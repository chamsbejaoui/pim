import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { AiService } from '../ai/ai.service';
import {
  PlayerStyleProfile,
  PlayerStyleProfileDocument
} from '../player-profiles/schemas/player-style-profile.schema';
import { Player, PlayerDocument } from '../players/schemas/player.schema';
import { AnalyzePairProfileDto } from './dto/analyze-pair-profile.dto';
import { AnalyzeSquadProfileDto } from './dto/analyze-squad-profile.dto';
import { GenerateStartingXiDto } from './dto/generate-starting-xi.dto';
import { ListChemistryPairsDto } from './dto/list-chemistry-pairs.dto';
import { PlayerNetworkQueryDto } from './dto/player-network-query.dto';
import { RatePairDto } from './dto/rate-pair.dto';
import { SetManualPairScoreDto } from './dto/set-manual-pair-score.dto';
import { LineupPlayerDto, ScoreLineupDto } from './dto/score-lineup.dto';
import { ChemistryPair, ChemistryPairDocument } from './schemas/chemistry-pair.schema';
import { Squad, SquadDocument } from '../squad/schemas/squad.schema';

type PlayerLite = {
  _id: Types.ObjectId;
  name?: string;
  firstName?: string;
  lastName?: string;
  position?: string;
};

type PairEvaluation = {
  playerAId: string;
  playerAName: string;
  playerAPosition?: string;
  playerBId: string;
  playerBName: string;
  playerBPosition?: string;
  rating: number | null;
  scoreSource?: 'manual' | 'observation' | 'ai';
  observationCount: number;
  status: 'known' | 'unknown';
  category?: 'excellent' | 'good' | 'neutral' | 'conflict';
  smartAlert?: string;
};

type PairScoreResolution = {
  rating: number | null;
  source?: 'manual' | 'observation' | 'ai';
};

type ChemistryRoleBucket = 'GK' | 'DEF' | 'MID' | 'ATT' | 'OTHER';

type ChemistryXiCandidate = PlayerLite & {
  speed?: number;
  endurance?: number;
  dribbles?: number;
  shots?: number;
  statistics?: {
    averageScore?: number;
    bestScore?: number;
    totalEvents?: number;
  };
};

type ChemistryXiSlot = {
  role: string;
  roleLabel: string;
  bucket: Exclude<ChemistryRoleBucket, 'OTHER'>;
  x: number;
  y: number;
};

type ChemistryXiPick = {
  player: ChemistryXiCandidate;
  slot: ChemistryXiSlot;
  chemistryFit: number;
  selectionScore: number;
  knownLinks: number;
  riskyLinks: number;
};

@Injectable()
export class ChemistryService {
  constructor(
    @InjectModel(ChemistryPair.name)
    private readonly chemistryPairModel: Model<ChemistryPairDocument>,
    @InjectModel(Player.name)
    private readonly playerModel: Model<PlayerDocument>,
    @InjectModel(PlayerStyleProfile.name)
    private readonly playerStyleProfileModel: Model<PlayerStyleProfileDocument>,
    @InjectModel(Squad.name)
    private readonly squadModel: Model<SquadDocument>,
    private readonly aiService: AiService
  ) {}

  async ratePair(dto: RatePairDto) {
    if (dto.playerAId === dto.playerBId) {
      throw new BadRequestException('A player pair must contain two distinct players');
    }

    await this.assertPlayersExist([dto.playerAId, dto.playerBId]);

    const [playerAId, playerBId] = this.normalizePairIds(dto.playerAId, dto.playerBId);
    const pairKey = this.buildPairKey(playerAId, playerBId);

    const existing = await this.chemistryPairModel.findOne({ season: dto.season, pairKey }).exec();

    if (!existing) {
      const created = await this.chemistryPairModel.create({
        season: dto.season,
        playerAId,
        playerBId,
        pairKey,
        averageRating: dto.rating,
        lastRating: dto.rating,
        observationCount: 1,
        observedBy: dto.observedBy,
        tacticalZone: dto.tacticalZone,
        notes: dto.notes,
        lastObservedAt: new Date()
      });

      return {
        message: 'Pair chemistry rating created',
        pair: await this.toPairView(created)
      };
    }

    const nextCount = existing.observationCount + 1;
    const nextAverage = Number(
      ((existing.averageRating * existing.observationCount + dto.rating) / nextCount).toFixed(2)
    );

    existing.averageRating = nextAverage;
    existing.lastRating = dto.rating;
    existing.observationCount = nextCount;
    existing.observedBy = dto.observedBy ?? existing.observedBy;
    existing.tacticalZone = dto.tacticalZone ?? existing.tacticalZone;
    existing.notes = dto.notes ?? existing.notes;
    existing.lastObservedAt = new Date();
    await existing.save();

    return {
      message: 'Pair chemistry rating updated',
      pair: await this.toPairView(existing)
    };
  }

  async analyzePairProfile(dto: AnalyzePairProfileDto) {
    if (dto.playerAId === dto.playerBId) {
      throw new BadRequestException('A player pair must contain two distinct players');
    }

    await this.assertPlayersExist([dto.playerAId, dto.playerBId]);

    const [playerAId, playerBId] = this.normalizePairIds(dto.playerAId, dto.playerBId);
    const pairKey = this.buildPairKey(playerAId, playerBId);

    const [profileA, profileB] = await Promise.all([
      this.playerStyleProfileModel.findOne({ season: dto.season, playerId: playerAId }).lean().exec(),
      this.playerStyleProfileModel.findOne({ season: dto.season, playerId: playerBId }).lean().exec()
    ]);

    if (!profileA || !profileB) {
      throw new BadRequestException(
        'Player style profiles are required for both players in the selected season'
      );
    }

    const playerMap = await this.getPlayerMapByIds([playerAId, playerBId]);
    const playerAName = playerMap.get(playerAId)
      ? this.getPlayerDisplayName(playerMap.get(playerAId) as PlayerLite)
      : playerAId;
    const playerBName = playerMap.get(playerBId)
      ? this.getPlayerDisplayName(playerMap.get(playerBId) as PlayerLite)
      : playerBId;

    const profileScore = this.computeProfileCompatibilityScore(profileA as any, profileB as any);
    const fallbackInsights = this.buildProfilePairInsights(playerAName, playerBName, profileScore);

    let aiScore = profileScore;
    let aiInsights: string[] | undefined;
    let aiInsightsSource: 'ai-service' | 'rule-based' | undefined;

    if (dto.includeAiInsights !== false) {
      const resolved = await this.resolveAiInsights(
        'pair_profile',
        dto.season,
        {
          playerA: {
            playerId: playerAId,
            playerName: playerAName,
            style: this.extractStyleVector(profileA as any)
          },
          playerB: {
            playerId: playerBId,
            playerName: playerBName,
            style: this.extractStyleVector(profileB as any)
          },
          baselineProfileScore: profileScore
        },
        fallbackInsights
      );

      aiInsights = resolved.insights;
      aiInsightsSource = resolved.source;
      if (typeof resolved.score === 'number') {
        aiScore = this.clampScore(resolved.score);
      }
    }

    let pair = await this.chemistryPairModel.findOne({ season: dto.season, pairKey }).exec();
    if (!pair) {
      pair = await this.chemistryPairModel.create({
        season: dto.season,
        playerAId,
        playerBId,
        pairKey,
        averageRating: 0,
        lastRating: 0,
        observationCount: 0
      });
    }

    pair.aiScore = Number(aiScore.toFixed(2));
    pair.aiScoreVersion = aiInsightsSource === 'ai-service' ? 'python-ai-service' : 'rule-based';
    pair.aiScoreComputedAt = new Date();
    await pair.save();

    return {
      message: 'AI chemistry analysis completed from player profiles',
      baselineProfileScore: profileScore,
      aiScore: pair.aiScore,
      aiInsights,
      aiInsightsSource,
      pair: await this.toPairView(pair)
    };
  }

  async analyzeSquadProfile(dto: AnalyzeSquadProfileDto) {
    const season = dto.season?.trim()?.length
      ? dto.season.trim()
      : await this.resolveSeasonForSquadAnalysis();

    const squad = await this.squadModel.findOne({ season }).lean().exec();
    if (!squad) {
      throw new BadRequestException(
        `No squad found for season "${season}". Create it before running squad chemistry analysis.`
      );
    }

    const candidatePlayerIds = Array.from(
      new Set((squad.playerIds ?? []).map((playerId) => String(playerId)))
    );
    if (candidatePlayerIds.length < 11) {
      throw new BadRequestException('Season squad must contain at least 11 players for chemistry analysis.');
    }

    await this.assertPlayersExist(candidatePlayerIds);

    const includeAiInsights = dto.includeAiInsights !== false;
    const formations = this.normalizeSquadFormationOptions(dto.formations);
    const starterIds = Array.from(new Set((squad.starterIds ?? []).map((playerId) => String(playerId))))
      .filter((playerId) => candidatePlayerIds.includes(playerId))
      .slice(0, 11);

    const players = (await this.playerModel
      .find({ _id: { $in: candidatePlayerIds } })
      .select('_id name firstName lastName position speed endurance dribbles shots statistics')
      .lean()
      .exec()) as ChemistryXiCandidate[];

    const playerMap = new Map<string, ChemistryXiCandidate>();
    for (const player of players) {
      playerMap.set(String(player._id), player);
    }

    const profileSummary = await this.ensureSquadProfiles(season, candidatePlayerIds, playerMap);
    const groupProfile = this.buildGroupProfile(profileSummary.profiles);

    let currentLineup: Record<string, any> | null = null;
    if (starterIds.length >= 3) {
      const lineupPlayers: LineupPlayerDto[] = starterIds.map((playerId) => ({
        playerId,
        position: playerMap.get(playerId)?.position
      }));

      currentLineup = (await this.scoreLineup({
        season,
        players: lineupPlayers,
        includeAiInsights
      })) as Record<string, any>;
    }

    const formationComparisons: Array<{
      formation: string;
      chemistryScore: number;
      knownPairCount: number;
      unknownPairCount: number;
      coverage: number;
    }> = [];

    const formationCandidates: Array<{
      formation: string;
      chemistryScore: number;
      data: Record<string, any>;
    }> = [];

    for (const formation of formations) {
      try {
        const generated = (await this.generateStartingXi({
          season,
          formation,
          candidatePlayerIds,
          poolLimit: Math.max(11, candidatePlayerIds.length),
          includeAiInsights
        })) as Record<string, any>;

        const summary = (generated.chemistryEvaluation?.summary ?? {}) as Record<string, any>;
        const chemistryScore = this.clampScore(
          Number(summary.chemistryScore ?? generated.chemistryScore ?? 0)
        );
        const knownPairCount = Number(summary.knownPairCount ?? 0);
        const unknownPairCount = Number(summary.unknownPairCount ?? 0);
        const rawCoverage = Number(summary.coverage ?? 0);

        formationComparisons.push({
          formation,
          chemistryScore,
          knownPairCount: Number.isFinite(knownPairCount) ? knownPairCount : 0,
          unknownPairCount: Number.isFinite(unknownPairCount) ? unknownPairCount : 0,
          coverage: Number.isFinite(rawCoverage) ? Number(rawCoverage.toFixed(1)) : 0
        });

        formationCandidates.push({
          formation,
          chemistryScore,
          data: generated
        });
      } catch {
        continue;
      }
    }

    if (formationCandidates.length === 0) {
      throw new BadRequestException(
        'Unable to evaluate the requested formations. Check squad data and try again.'
      );
    }

    formationCandidates.sort((left, right) => right.chemistryScore - left.chemistryScore);
    formationComparisons.sort((left, right) => right.chemistryScore - left.chemistryScore);

    const bestFormationCandidate = formationCandidates[0];
    const bestFormation = {
      ...bestFormationCandidate.data,
      formation: bestFormationCandidate.formation
    };

    const bestFormationScore = bestFormationCandidate.chemistryScore;
    const currentStarterScoreRaw = Number(currentLineup?.summary?.chemistryScore);
    const currentStarterScore = Number.isFinite(currentStarterScoreRaw)
      ? this.clampScore(currentStarterScoreRaw)
      : null;

    const styleCohesionScore = this.computeStyleCohesionScore(groupProfile.style);
    const squadScore = this.clampScore(
      currentStarterScore === null
        ? bestFormationScore * 0.55 + styleCohesionScore * 0.45
        : bestFormationScore * 0.5 + currentStarterScore * 0.3 + styleCohesionScore * 0.2
    );

    const bestPairs = await this.getBestPairs({
      season,
      threshold: 7.5,
      limit: 8,
      includeAiInsights
    });
    const conflicts = await this.getConflicts({
      season,
      threshold: 5,
      limit: 8,
      includeAiInsights
    });

    return {
      season,
      profiles: {
        complete: profileSummary.complete,
        createdProfiles: profileSummary.createdProfiles,
        totalProfiles: profileSummary.totalProfiles,
        totalPlayers: candidatePlayerIds.length
      },
      groupProfile,
      formationComparisons,
      bestFormation,
      currentLineup,
      chemistrySummary: {
        squadScore,
        squadLabel: this.squadScoreLabel(squadScore),
        bestFormation: bestFormationCandidate.formation,
        bestFormationScore,
        currentStarterScore,
        styleCohesionScore
      },
      bestPairs,
      conflicts
    };
  }

  async setManualPairScore(dto: SetManualPairScoreDto) {
    if (dto.playerAId === dto.playerBId) {
      throw new BadRequestException('A player pair must contain two distinct players');
    }

    await this.assertPlayersExist([dto.playerAId, dto.playerBId]);

    const [playerAId, playerBId] = this.normalizePairIds(dto.playerAId, dto.playerBId);
    const pairKey = this.buildPairKey(playerAId, playerBId);

    let pair = await this.chemistryPairModel.findOne({ season: dto.season, pairKey }).exec();
    if (!pair) {
      pair = await this.chemistryPairModel.create({
        season: dto.season,
        playerAId,
        playerBId,
        pairKey,
        averageRating: 0,
        lastRating: 0,
        observationCount: 0
      });
    }

    pair.manualScore = Number(dto.manualScore.toFixed(2));
    pair.manualScoreBy = dto.manualScoreBy;
    pair.manualScoreReason = dto.manualScoreReason;
    pair.manualScoreUpdatedAt = new Date();
    await pair.save();

    return {
      message: 'Manual score saved. Manual score now has priority over AI and observed scores.',
      pair: await this.toPairView(pair)
    };
  }

  async getMatrix(season: string) {
    const pairs = await this.chemistryPairModel.find({ season }).sort({ averageRating: -1 }).lean().exec();
    const playerIds = this.collectUniquePlayerIdsFromPairs(pairs);
    const players = await this.getPlayersByIds(playerIds);

    const pairMap = new Map<string, ChemistryPair>();
    for (const pair of pairs) {
      pairMap.set(pair.pairKey, pair as ChemistryPair);
    }

    const matrix = players.map((playerA) => {
      const relations = players.map((playerB) => {
        if (String(playerA._id) === String(playerB._id)) {
          return {
            playerId: String(playerB._id),
            playerName: this.getPlayerDisplayName(playerB),
            rating: null,
            observationCount: 0,
            status: 'self'
          };
        }

        const key = this.buildPairKey(String(playerA._id), String(playerB._id));
        const pair = pairMap.get(key);
        const effectiveScore = pair ? this.resolvePairScore(pair) : { rating: null };

        return {
          playerId: String(playerB._id),
          playerName: this.getPlayerDisplayName(playerB),
          rating: effectiveScore.rating,
          scoreSource: effectiveScore.source,
          observationCount: pair?.observationCount ?? 0,
          status: pair ? 'known' : 'unknown'
        };
      });

      return {
        playerId: String(playerA._id),
        playerName: this.getPlayerDisplayName(playerA),
        position: playerA.position,
        relations
      };
    });

    return {
      season,
      players: players.map((player) => ({
        playerId: String(player._id),
        playerName: this.getPlayerDisplayName(player),
        position: player.position
      })),
      matrix
    };
  }

  async getGraph(season: string) {
    const pairs = await this.chemistryPairModel.find({ season }).sort({ averageRating: -1 }).lean().exec();
    const playerIds = this.collectUniquePlayerIdsFromPairs(pairs);
    const players = await this.getPlayersByIds(playerIds);

    const nodes = players.map((player) => ({
      id: String(player._id),
      label: this.getPlayerDisplayName(player),
      position: player.position
    }));

    const edges = pairs
      .map((pair) => {
        const effectiveScore = this.resolvePairScore(pair as ChemistryPair);
        if (effectiveScore.rating === null) {
          return null;
        }

        return {
          source: String(pair.playerAId),
          target: String(pair.playerBId),
          weight: effectiveScore.rating,
          scoreSource: effectiveScore.source,
          observationCount: pair.observationCount,
          category: this.ratingCategory(effectiveScore.rating),
          warning: effectiveScore.rating <= 4
        };
      })
      .filter((edge): edge is NonNullable<typeof edge> => edge !== null);

    return {
      season,
      nodes,
      edges
    };
  }

  async getBestPairs(query: ListChemistryPairsDto) {
    const season = query.season ?? (await this.resolveLatestSeason());
    const threshold = query.threshold ?? 8;
    const limit = query.limit ?? 10;

    const pairs = await this.chemistryPairModel.find({ season }).lean().exec();

    const allPairViews = await this.toPairViews(pairs as ChemistryPair[]);
    const pairViews = allPairViews
      .filter((pair) => typeof pair.effectiveRating === 'number' && pair.effectiveRating >= threshold)
      .sort((a, b) => {
        const left = typeof a.effectiveRating === 'number' ? a.effectiveRating : -1;
        const right = typeof b.effectiveRating === 'number' ? b.effectiveRating : -1;
        if (right !== left) {
          return right - left;
        }
        return (b.observationCount ?? 0) - (a.observationCount ?? 0);
      })
      .slice(0, limit);
    let aiInsights: string[] | undefined;
    let aiInsightsSource: 'ai-service' | 'rule-based' | undefined;

    if (query.includeAiInsights) {
      const fallbackInsights = this.buildAiPairInsights(
        pairViews.map((pair) => ({
          averageRating: typeof pair.effectiveRating === 'number' ? pair.effectiveRating : 0,
          playerAName: pair.playerAName,
          playerBName: pair.playerBName
        })),
        'best'
      );
      const resolved = await this.resolveAiInsights(
        'best_pairs',
        season,
        {
          threshold,
          limit,
          pairs: pairViews
        },
        fallbackInsights
      );
      aiInsights = resolved.insights;
      aiInsightsSource = resolved.source;
    }

    return {
      season,
      threshold,
      pairs: pairViews,
      aiInsights,
      aiInsightsSource
    };
  }

  async getConflicts(query: ListChemistryPairsDto) {
    const season = query.season ?? (await this.resolveLatestSeason());
    const threshold = query.threshold ?? 4.5;
    const limit = query.limit ?? 10;

    const pairs = await this.chemistryPairModel.find({ season }).lean().exec();

    const allPairViews = await this.toPairViews(pairs as ChemistryPair[]);
    const pairViews = allPairViews
      .filter((pair) => typeof pair.effectiveRating === 'number' && pair.effectiveRating <= threshold)
      .sort((a, b) => {
        const left = typeof a.effectiveRating === 'number' ? a.effectiveRating : 11;
        const right = typeof b.effectiveRating === 'number' ? b.effectiveRating : 11;
        if (left !== right) {
          return left - right;
        }
        return (b.observationCount ?? 0) - (a.observationCount ?? 0);
      })
      .slice(0, limit);
    let aiInsights: string[] | undefined;
    let aiInsightsSource: 'ai-service' | 'rule-based' | undefined;

    if (query.includeAiInsights) {
      const fallbackInsights = this.buildAiPairInsights(
        pairViews.map((pair) => ({
          averageRating: typeof pair.effectiveRating === 'number' ? pair.effectiveRating : 0,
          playerAName: pair.playerAName,
          playerBName: pair.playerBName
        })),
        'conflict'
      );
      const resolved = await this.resolveAiInsights(
        'conflicts',
        season,
        {
          threshold,
          limit,
          pairs: pairViews
        },
        fallbackInsights
      );
      aiInsights = resolved.insights;
      aiInsightsSource = resolved.source;
    }

    return {
      season,
      threshold,
      pairs: pairViews,
      aiInsights,
      aiInsightsSource
    };
  }

  async scoreLineup(dto: ScoreLineupDto) {
    const lineup = this.normalizeLineup(dto);
    const season = dto.season ?? (await this.resolveLatestSeason());

    if (lineup.length < 3) {
      throw new BadRequestException('Lineup must contain at least 3 players');
    }

    await this.assertPlayersExist(lineup.map((entry) => entry.playerId));
    const playerMap = await this.getPlayerMapByIds(lineup.map((entry) => entry.playerId));

    const pairKeys = this.lineupPairKeys(lineup.map((entry) => entry.playerId));
    const pairs = await this.chemistryPairModel.find({ season, pairKey: { $in: pairKeys } }).lean().exec();
    const pairMap = new Map<string, ChemistryPair>();
    for (const pair of pairs) {
      pairMap.set(pair.pairKey, pair as ChemistryPair);
    }

    const evaluations: PairEvaluation[] = [];
    for (let i = 0; i < lineup.length; i += 1) {
      for (let j = i + 1; j < lineup.length; j += 1) {
        const a = lineup[i];
        const b = lineup[j];
        const aPlayer = playerMap.get(a.playerId);
        const bPlayer = playerMap.get(b.playerId);

        if (!aPlayer || !bPlayer) {
          continue;
        }

        const pairKey = this.buildPairKey(a.playerId, b.playerId);
        const known = pairMap.get(pairKey);
        const effectiveScore = known ? this.resolvePairScore(known) : { rating: null };
        const rating = effectiveScore.rating;

        evaluations.push({
          playerAId: a.playerId,
          playerAName: this.getPlayerDisplayName(aPlayer),
          playerAPosition: a.position ?? aPlayer.position,
          playerBId: b.playerId,
          playerBName: this.getPlayerDisplayName(bPlayer),
          playerBPosition: b.position ?? bPlayer.position,
          rating,
          scoreSource: effectiveScore.source,
          observationCount: known?.observationCount ?? 0,
          status: rating !== null ? 'known' : 'unknown',
          category: rating !== null ? this.ratingCategory(rating) : undefined,
          smartAlert: this.pairSmartAlert(rating, a.position ?? aPlayer.position, b.position ?? bPlayer.position)
        });
      }
    }

    const knownRatings = evaluations.filter((item) => item.rating !== null).map((item) => item.rating as number);
    const chemistryScore = knownRatings.length
      ? Number((knownRatings.reduce((sum, value) => sum + value, 0) / knownRatings.length).toFixed(2))
      : 0;

    const centralTriangle = this.centralTriangleScore(evaluations);
    const defensiveCore = this.defensiveCoreScore(evaluations);
    const leftFlankWeakLink = evaluations
      .filter((item) => this.isLeftCorridor(item.playerAPosition) || this.isLeftCorridor(item.playerBPosition))
      .sort((a, b) => (a.rating ?? 11) - (b.rating ?? 11))[0];

    const summary = {
      chemistryScore,
      knownPairCount: knownRatings.length,
      unknownPairCount: evaluations.length - knownRatings.length,
      coverage: Number(((knownRatings.length / Math.max(evaluations.length, 1)) * 100).toFixed(1))
    };

    const smartPairingAlerts = this.buildLineupSmartAlerts(evaluations);
    let aiInsights: string[] | undefined;
    let aiInsightsSource: 'ai-service' | 'rule-based' | undefined;

    if (dto.includeAiInsights) {
      const fallbackInsights = this.buildAiLineupInsights(
        summary.chemistryScore,
        summary.coverage,
        smartPairingAlerts
      );
      const resolved = await this.resolveAiInsights(
        'lineup',
        season,
        {
          summary,
          impact: {
            centralTriangle,
            defensiveCore,
            leftFlankWeakLink
          },
          smartPairingAlerts,
          pairCount: evaluations.length,
          knownPairCount: knownRatings.length
        },
        fallbackInsights
      );
      aiInsights = resolved.insights;
      aiInsightsSource = resolved.source;
    }

    return {
      season,
      lineupSize: lineup.length,
      summary,
      impact: {
        centralTriangle,
        defensiveCore,
        leftFlankWeakLink
      },
      smartPairingAlerts,
      pairs: evaluations,
      aiInsights,
      aiInsightsSource
    };
  }

  async generateStartingXi(dto: GenerateStartingXiDto) {
    const season = dto.season ?? (await this.resolveSeasonForGeneration());
    const includeAiInsights = dto.includeAiInsights !== false;
    const formation = this.normalizeFormation(dto.formation);
    const poolLimit = dto.poolLimit ?? 60;

    const candidates = await this.getChemistryXiCandidates(dto.candidatePlayerIds, poolLimit);
    if (candidates.length < 11) {
      throw new BadRequestException('At least 11 players are required to generate a starting XI');
    }

    const candidateIds = candidates.map((player) => String(player._id));
    const pairKeys = this.lineupPairKeys(candidateIds);
    const pairs = pairKeys.length
      ? await this.chemistryPairModel.find({ season, pairKey: { $in: pairKeys } }).lean().exec()
      : [];

    const pairMap = new Map<string, ChemistryPair>();
    for (const pair of pairs) {
      pairMap.set(pair.pairKey, pair as ChemistryPair);
    }

    const slots = this.buildChemistryXiSlots(formation);
    const selectedIds = new Set<string>();
    const selected: ChemistryXiPick[] = [];

    for (const slot of slots) {
      const pick = this.pickBestChemistryXiCandidate(slot, candidates, selected, selectedIds, pairMap);
      if (!pick) {
        continue;
      }
      selectedIds.add(String(pick.player._id));
      selected.push(pick);
    }

    if (selected.length < 11) {
      throw new BadRequestException('Unable to build a complete XI with the provided candidate pool');
    }

    const lineupPlayers: LineupPlayerDto[] = selected.map((item) => ({
      playerId: String(item.player._id),
      position: item.slot.role
    }));

    const chemistryEvaluation = await this.scoreLineup({
      season,
      players: lineupPlayers,
      includeAiInsights
    });

    const startingXi = selected.map((item) => {
      const playerId = String(item.player._id);
      const playerName = this.getPlayerDisplayName(item.player);
      return {
        playerId,
        playerName,
        naturalPosition: item.player.position,
        role: item.slot.role,
        roleLabel: item.slot.roleLabel,
        x: Number(item.slot.x.toFixed(3)),
        y: Number(item.slot.y.toFixed(3)),
        chemistryFit: Number(item.chemistryFit.toFixed(2)),
        selectionScore: Number(item.selectionScore.toFixed(3)),
        knownLinks: item.knownLinks,
        riskyLinks: item.riskyLinks
      };
    });

    const startingXiLegacy = startingXi.map((item) => ({
      player_id: item.playerId,
      player_name: item.playerName,
      role: item.role,
      role_label: item.roleLabel,
      x: item.x,
      y: item.y,
      chemistry_fit: item.chemistryFit,
      selection_score: item.selectionScore,
      known_links: item.knownLinks,
      risky_links: item.riskyLinks
    }));

    return {
      message: 'Chemistry-based starting XI generated',
      season,
      formation,
      strategy: 'chemistry-greedy-v1',
      candidatePoolSize: candidates.length,
      startingXi,
      starting_xi: startingXiLegacy,
      chemistryEvaluation,
      chemistryScore: chemistryEvaluation.summary?.chemistryScore ?? null
    };
  }

  async getPlayerNetwork(playerId: string, query: PlayerNetworkQueryDto) {
    if (!Types.ObjectId.isValid(playerId)) {
      throw new BadRequestException('Invalid player ID');
    }

    const season = query.season ?? (await this.resolveLatestSeason());
    const player = await this.playerModel.findById(playerId).lean().exec();
    if (!player) {
      throw new NotFoundException(`Player with ID "${playerId}" not found`);
    }

    const pairs = await this.chemistryPairModel
      .find({ season, $or: [{ playerAId: playerId }, { playerBId: playerId }] })
      .sort({ averageRating: -1 })
      .lean()
      .exec();

    const teammateIds = new Set<string>();
    for (const pair of pairs) {
      const teammate = String(pair.playerAId) === playerId ? String(pair.playerBId) : String(pair.playerAId);
      teammateIds.add(teammate);
    }

    const teammates = await this.getPlayerMapByIds(Array.from(teammateIds));
    const connections = pairs.map((pair) => {
      const teammateId = String(pair.playerAId) === playerId ? String(pair.playerBId) : String(pair.playerAId);
      const teammate = teammates.get(teammateId);
      const effectiveScore = this.resolvePairScore(pair as ChemistryPair);

      return {
        teammateId,
        teammateName: teammate ? this.getPlayerDisplayName(teammate) : teammateId,
        teammatePosition: teammate?.position,
        rating: effectiveScore.rating,
        scoreSource: effectiveScore.source,
        observationCount: pair.observationCount,
        category: effectiveScore.rating !== null ? this.ratingCategory(effectiveScore.rating) : 'neutral'
      };
    });

    const knownConnections = connections.filter(
      (connection): connection is typeof connection & { rating: number } => typeof connection.rating === 'number'
    );
    const average = knownConnections.length
      ? Number(
          (
            knownConnections.reduce((sum, item) => sum + item.rating, 0) /
            knownConnections.length
          ).toFixed(2)
        )
      : null;

    const playerName = this.getPlayerDisplayName(player as PlayerLite);
    let aiInsights: string[] | undefined;
    let aiInsightsSource: 'ai-service' | 'rule-based' | undefined;

    if (query.includeAiInsights) {
      const fallbackInsights = this.buildAiNetworkInsights(connections);
      const resolved = await this.resolveAiInsights(
        'player_network',
        season,
        {
          player: {
            playerId,
            playerName,
            position: player.position
          },
          summary: {
            connectionCount: knownConnections.length,
            averageRating: average
          },
          connections: connections.slice(0, 20)
        },
        fallbackInsights
      );
      aiInsights = resolved.insights;
      aiInsightsSource = resolved.source;
    }

    return {
      season,
      player: {
        playerId,
        playerName,
        position: player.position
      },
      summary: {
        connectionCount: knownConnections.length,
        averageRating: average
      },
      connections,
      aiInsights,
      aiInsightsSource
    };
  }

  private normalizeLineup(dto: ScoreLineupDto): LineupPlayerDto[] {
    if (dto.players?.length) {
      return dto.players.map((player) => ({
        playerId: player.playerId,
        position: player.position
      }));
    }

    if (!dto.playerIds?.length) {
      throw new BadRequestException('Provide either "players" or "playerIds" to score a lineup');
    }

    return dto.playerIds.map((playerId) => ({ playerId }));
  }

  private async resolveSeasonForSquadAnalysis(): Promise<string> {
    const latestSquad = await this.squadModel.findOne().sort({ season: -1, updatedAt: -1 }).lean().exec();
    if (latestSquad?.season) {
      return latestSquad.season;
    }

    return this.resolveSeasonForGeneration();
  }

  private normalizeSquadFormationOptions(formations?: string[]): string[] {
    const defaults = ['4-3-3', '4-2-3-1', '3-5-2'];
    const source = formations?.length ? formations : defaults;

    const normalized = Array.from(
      new Set(
        source
          .map((formation) => this.normalizeFormation(formation))
          .filter((formation) => formation.length > 0)
      )
    );

    if (normalized.length === 0) {
      return defaults;
    }

    return normalized.slice(0, 8);
  }

  private async ensureSquadProfiles(
    season: string,
    playerIds: string[],
    playerMap: Map<string, ChemistryXiCandidate>
  ): Promise<{
    profiles: Array<Record<string, unknown>>;
    createdProfiles: number;
    totalProfiles: number;
    complete: boolean;
  }> {
    const existingProfiles = await this.playerStyleProfileModel
      .find({ season, playerId: { $in: playerIds } })
      .lean()
      .exec();

    const existingIds = new Set(existingProfiles.map((profile: any) => String(profile.playerId)));
    const missingPlayerIds = playerIds.filter((playerId) => !existingIds.has(playerId));

    if (missingPlayerIds.length > 0) {
      const payload = missingPlayerIds.map((playerId) =>
        this.buildAutoProfilePayload(season, playerId, playerMap.get(playerId))
      );

      try {
        await this.playerStyleProfileModel.insertMany(payload, { ordered: false });
      } catch (error) {
        const message = (error as Error)?.message ?? '';
        if (!message.includes('E11000')) {
          throw error;
        }
      }
    }

    const profiles = (await this.playerStyleProfileModel
      .find({ season, playerId: { $in: playerIds } })
      .lean()
      .exec()) as Array<Record<string, unknown>>;

    return {
      profiles,
      createdProfiles: missingPlayerIds.length,
      totalProfiles: profiles.length,
      complete: profiles.length === playerIds.length
    };
  }

  private buildAutoProfilePayload(
    season: string,
    playerId: string,
    player?: ChemistryXiCandidate
  ): Record<string, unknown> {
    const speed = this.normalizeMetricToTen(player?.speed, 100, 5);
    const endurance = this.normalizeMetricToTen(player?.endurance, 100, 5);
    const dribbles = this.normalizeMetricToTen(player?.dribbles, 20, 5);
    const shots = this.normalizeMetricToTen(player?.shots, 20, 5);
    const averageScore = this.normalizeMetricToTen(player?.statistics?.averageScore, 10, 5);
    const bucket = this.roleBucketFromPosition(player?.position);

    const attackingBias = bucket === 'ATT' ? 1 : 0;
    const midfieldBias = bucket === 'MID' ? 1 : 0;
    const defensiveBias = bucket === 'DEF' ? 1 : 0;
    const goalkeeperBias = bucket === 'GK' ? 1 : 0;

    return {
      season,
      playerId,
      possessionPlay: this.clampScore(4.8 + midfieldBias * 0.7 + averageScore * 0.15),
      selfishness: this.clampScore(4.5 + attackingBias * 0.9 + (shots - dribbles) * 0.2),
      oneTouchPreference: this.clampScore(4.6 + midfieldBias * 0.6 + averageScore * 0.18),
      directPlay: this.clampScore(4.4 + attackingBias * 0.8 + speed * 0.18),
      riskTaking: this.clampScore(4.2 + attackingBias * 0.7 + dribbles * 0.15),
      pressingIntensity: this.clampScore(4.3 + endurance * 0.22 + midfieldBias * 0.4),
      offBallMovement: this.clampScore(4.5 + attackingBias * 0.55 + speed * 0.2),
      communication: this.clampScore(4.7 + midfieldBias * 0.4 + defensiveBias * 0.35 + averageScore * 0.12),
      defensiveDiscipline: this.clampScore(4.3 + defensiveBias * 0.9 + goalkeeperBias * 0.8 + endurance * 0.15),
      creativity: this.clampScore(4.2 + dribbles * 0.22 + averageScore * 0.2),
      preferredStyles: this.inferPreferredStyles(player),
      notes: 'Auto-generated from player attributes for squad chemistry analysis.',
      updatedBy: 'system:auto-profile'
    };
  }

  private inferPreferredStyles(player?: ChemistryXiCandidate): string[] {
    if (!player) {
      return ['balanced'];
    }

    const styles: string[] = [];
    const bucket = this.roleBucketFromPosition(player.position);
    const speed = this.normalizeMetricToTen(player.speed, 100, 5);
    const endurance = this.normalizeMetricToTen(player.endurance, 100, 5);
    const dribbles = this.normalizeMetricToTen(player.dribbles, 20, 5);

    if (bucket === 'DEF' || bucket === 'GK') {
      styles.push('defensive-solidity');
    }
    if (bucket === 'MID') {
      styles.push('possession-control');
    }
    if (bucket === 'ATT') {
      styles.push('vertical-attacking');
    }
    if (speed >= 7) {
      styles.push('fast-transitions');
    }
    if (dribbles >= 7) {
      styles.push('creative-carry');
    }
    if (endurance >= 7) {
      styles.push('high-pressing');
    }

    if (styles.length === 0) {
      styles.push('balanced');
    }

    return Array.from(new Set(styles)).slice(0, 3);
  }

  private buildGroupProfile(profiles: Array<Record<string, unknown>>): {
    identity: string;
    style: Record<string, number>;
  } {
    const vectors = profiles.map((profile) => this.extractStyleVector(profile));
    const denominator = Math.max(vectors.length, 1);

    const style = {
      possessionPlay: this.clampScore(
        Number((vectors.reduce((sum, vector) => sum + vector.possessionPlay, 0) / denominator).toFixed(2))
      ),
      selfishness: this.clampScore(
        Number((vectors.reduce((sum, vector) => sum + vector.selfishness, 0) / denominator).toFixed(2))
      ),
      oneTouchPreference: this.clampScore(
        Number((vectors.reduce((sum, vector) => sum + vector.oneTouchPreference, 0) / denominator).toFixed(2))
      ),
      directPlay: this.clampScore(
        Number((vectors.reduce((sum, vector) => sum + vector.directPlay, 0) / denominator).toFixed(2))
      ),
      riskTaking: this.clampScore(
        Number((vectors.reduce((sum, vector) => sum + vector.riskTaking, 0) / denominator).toFixed(2))
      ),
      pressingIntensity: this.clampScore(
        Number((vectors.reduce((sum, vector) => sum + vector.pressingIntensity, 0) / denominator).toFixed(2))
      ),
      offBallMovement: this.clampScore(
        Number((vectors.reduce((sum, vector) => sum + vector.offBallMovement, 0) / denominator).toFixed(2))
      ),
      communication: this.clampScore(
        Number((vectors.reduce((sum, vector) => sum + vector.communication, 0) / denominator).toFixed(2))
      ),
      defensiveDiscipline: this.clampScore(
        Number((vectors.reduce((sum, vector) => sum + vector.defensiveDiscipline, 0) / denominator).toFixed(2))
      ),
      creativity: this.clampScore(
        Number((vectors.reduce((sum, vector) => sum + vector.creativity, 0) / denominator).toFixed(2))
      )
    };

    return {
      identity: this.describeGroupIdentity(style),
      style
    };
  }

  private describeGroupIdentity(style: Record<string, number>): string {
    const possession = style.possessionPlay ?? 5;
    const oneTouch = style.oneTouchPreference ?? 5;
    const directPlay = style.directPlay ?? 5;
    const risk = style.riskTaking ?? 5;
    const pressing = style.pressingIntensity ?? 5;
    const movement = style.offBallMovement ?? 5;
    const communication = style.communication ?? 5;
    const discipline = style.defensiveDiscipline ?? 5;

    if (pressing >= 7.2 && movement >= 7) {
      return 'High pressing collective with proactive movement.';
    }
    if (possession >= 7 && oneTouch >= 6.5) {
      return 'Possession-oriented squad with short passing combinations.';
    }
    if (directPlay >= 7 && risk >= 6.5) {
      return 'Vertical transition squad that attacks space quickly.';
    }
    if (discipline >= 7 && communication >= 6.5) {
      return 'Compact and disciplined block focused on defensive stability.';
    }

    return 'Balanced squad profile with adaptable game model.';
  }

  private computeStyleCohesionScore(style: Record<string, number>): number {
    const values = Object.values(style).filter((value) => Number.isFinite(value));
    if (values.length === 0) {
      return 5;
    }

    const mean = values.reduce((sum, value) => sum + value, 0) / values.length;
    const variance = values.reduce((sum, value) => sum + (value - mean) ** 2, 0) / values.length;
    const stdev = Math.sqrt(variance);

    const communication = style.communication ?? 5;
    const movement = style.offBallMovement ?? 5;

    return this.clampScore(10 - stdev * 1.1 + communication * 0.15 + movement * 0.1);
  }

  private squadScoreLabel(score: number): string {
    if (score >= 8.5) {
      return 'Elite';
    }
    if (score >= 7.2) {
      return 'Strong';
    }
    if (score >= 6) {
      return 'Stable';
    }
    if (score >= 4.5) {
      return 'Fragile';
    }
    return 'Critical';
  }

  private async getChemistryXiCandidates(candidatePlayerIds: string[] | undefined, poolLimit: number) {
    const normalizedLimit = Math.max(11, Math.min(120, Math.floor(poolLimit)));
    const projection = '_id name firstName lastName position speed endurance dribbles shots statistics status';

    if (candidatePlayerIds?.length) {
      const uniqueIds = Array.from(new Set(candidatePlayerIds));
      await this.assertPlayersExist(uniqueIds);

      const players = await this.playerModel
        .find({ _id: { $in: uniqueIds } })
        .select(projection)
        .lean()
        .exec();

      const sorted = (players as ChemistryXiCandidate[]).sort(
        (a, b) => this.playerQualityScore(b) - this.playerQualityScore(a)
      );
      return sorted.slice(0, normalizedLimit);
    }

    const players = await this.playerModel
      .find({ $or: [{ status: 'active' }, { status: { $exists: false } }] })
      .select(projection)
      .lean()
      .exec();

    const sorted = (players as ChemistryXiCandidate[]).sort(
      (a, b) => this.playerQualityScore(b) - this.playerQualityScore(a)
    );

    return this.buildBalancedCandidatePool(sorted, normalizedLimit);
  }

  private buildBalancedCandidatePool(players: ChemistryXiCandidate[], limit: number): ChemistryXiCandidate[] {
    if (players.length <= limit) {
      return players;
    }

    const selected: ChemistryXiCandidate[] = [];
    const selectedIds = new Set<string>();

    const push = (player: ChemistryXiCandidate) => {
      const id = String(player._id);
      if (selected.length >= limit || selectedIds.has(id)) {
        return;
      }
      selectedIds.add(id);
      selected.push(player);
    };

    const byBucket = (bucket: Exclude<ChemistryRoleBucket, 'OTHER'>) =>
      players.filter((player) => this.roleBucketFromPosition(player.position) === bucket);

    for (const player of byBucket('GK').slice(0, 2)) {
      push(player);
    }
    for (const player of byBucket('DEF').slice(0, 16)) {
      push(player);
    }
    for (const player of byBucket('MID').slice(0, 16)) {
      push(player);
    }
    for (const player of byBucket('ATT').slice(0, 14)) {
      push(player);
    }

    for (const player of players) {
      push(player);
      if (selected.length >= limit) {
        break;
      }
    }

    const hasGoalkeeper = selected.some(
      (player) => this.roleBucketFromPosition(player.position) === 'GK'
    );

    if (!hasGoalkeeper) {
      const fallbackGk = players.find(
        (player) => this.roleBucketFromPosition(player.position) === 'GK'
      );
      if (fallbackGk) {
        selected[selected.length - 1] = fallbackGk;
      }
    }

    return selected;
  }

  private pickBestChemistryXiCandidate(
    slot: ChemistryXiSlot,
    candidates: ChemistryXiCandidate[],
    selected: ChemistryXiPick[],
    selectedIds: Set<string>,
    pairMap: Map<string, ChemistryPair>
  ): ChemistryXiPick | null {
    let best: ChemistryXiPick | null = null;

    for (const candidate of candidates) {
      const candidateId = String(candidate._id);
      if (selectedIds.has(candidateId)) {
        continue;
      }

      const roleFit = this.roleFitScore(candidate.position, slot.bucket);
      const quality = this.playerQualityScore(candidate);
      const links = this.evaluateChemistryLinks(candidateId, selected, pairMap);
      const chemistryBase = selected.length > 0 ? links.averageRating : 6.5;

      const selectionScore =
        chemistryBase * 0.58 +
        quality * 0.24 +
        roleFit * 2.1 +
        links.coverage * 1.1 -
        links.riskyLinks * 0.35;

      if (!best || selectionScore > best.selectionScore) {
        best = {
          player: candidate,
          slot,
          chemistryFit: chemistryBase,
          selectionScore,
          knownLinks: links.knownLinks,
          riskyLinks: links.riskyLinks
        };
      }
    }

    return best;
  }

  private evaluateChemistryLinks(
    candidateId: string,
    selected: ChemistryXiPick[],
    pairMap: Map<string, ChemistryPair>
  ) {
    if (selected.length === 0) {
      return {
        averageRating: 6.5,
        knownLinks: 0,
        riskyLinks: 0,
        coverage: 0
      };
    }

    const ratings: number[] = [];
    let knownLinks = 0;
    let riskyLinks = 0;

    for (const pick of selected) {
      const pair = pairMap.get(this.buildPairKey(candidateId, String(pick.player._id)));
      if (!pair) {
        continue;
      }

      const resolved = this.resolvePairScore(pair);
      if (resolved.rating === null) {
        continue;
      }

      ratings.push(resolved.rating);
      knownLinks += 1;
      if (resolved.rating <= 4.5) {
        riskyLinks += 1;
      }
    }

    const baseAverage = ratings.length
      ? ratings.reduce((sum, value) => sum + value, 0) / ratings.length
      : 5.5;

    const blendedAverage = Number(
      (
        ((baseAverage * knownLinks) + 5.5 * (selected.length - knownLinks)) /
        Math.max(selected.length, 1)
      ).toFixed(2)
    );

    return {
      averageRating: blendedAverage,
      knownLinks,
      riskyLinks,
      coverage: Number((knownLinks / selected.length).toFixed(2))
    };
  }

  private buildChemistryXiSlots(formation: string): ChemistryXiSlot[] {
    const lines = this.parseFormation(formation);
    const slots: ChemistryXiSlot[] = [
      {
        role: 'GK',
        roleLabel: 'Goalkeeper',
        bucket: 'GK',
        x: 0.5,
        y: 0.92
      }
    ];

    const lineY = this.computeXiLineY(lines.length);

    lines.forEach((count, lineIndex) => {
      const bucket: Exclude<ChemistryRoleBucket, 'OTHER'> =
        lineIndex === 0 ? 'DEF' : lineIndex === lines.length - 1 ? 'ATT' : 'MID';
      const prefix = bucket === 'DEF' ? 'D' : bucket === 'MID' ? 'M' : 'A';
      const roleLabel = bucket === 'DEF' ? 'Defender' : bucket === 'MID' ? 'Midfielder' : 'Forward';
      const xPositions = this.computeXiXPositions(count);

      for (let i = 0; i < count; i += 1) {
        slots.push({
          role: `${prefix}${i + 1}`,
          roleLabel,
          bucket,
          x: xPositions[i],
          y: lineY[lineIndex]
        });
      }
    });

    return slots.slice(0, 11);
  }

  private normalizeFormation(formation?: string): string {
    return this.parseFormation(formation).join('-');
  }

  private parseFormation(formation?: string): number[] {
    if (!formation || formation.trim().length === 0) {
      return [4, 3, 3];
    }

    const values = formation
      .split('-')
      .map((value) => Number(value.trim()))
      .filter((value) => Number.isFinite(value) && value > 0 && value <= 8);

    if (values.length < 3 || values.length > 4) {
      return [4, 3, 3];
    }

    const sum = values.reduce((total, value) => total + value, 0);
    if (sum !== 10) {
      return [4, 3, 3];
    }

    return values;
  }

  private computeXiXPositions(count: number): number[] {
    if (count <= 1) {
      return [0.5];
    }
    const spacing = 0.8 / (count - 1);
    return Array.from({ length: count }, (_, index) => 0.1 + spacing * index);
  }

  private computeXiLineY(lines: number): number[] {
    if (lines <= 1) {
      return [0.6];
    }
    const minY = 0.18;
    const maxY = 0.76;
    const spacing = (maxY - minY) / (lines - 1);
    return Array.from({ length: lines }, (_, index) => minY + spacing * index);
  }

  private roleBucketFromPosition(position?: string): ChemistryRoleBucket {
    if (this.isGoalkeeperPosition(position)) {
      return 'GK';
    }
    if (this.isDefenderPosition(position)) {
      return 'DEF';
    }
    if (this.isMidfielderPosition(position)) {
      return 'MID';
    }
    if (this.isAttackerPosition(position)) {
      return 'ATT';
    }
    return 'OTHER';
  }

  private roleFitScore(position: string | undefined, bucket: Exclude<ChemistryRoleBucket, 'OTHER'>): number {
    const playerBucket = this.roleBucketFromPosition(position);
    if (playerBucket === bucket) {
      return 1;
    }

    if (bucket === 'GK') {
      return playerBucket === 'OTHER' ? 0.15 : 0.05;
    }

    if (playerBucket === 'OTHER') {
      return 0.55;
    }

    if (bucket === 'DEF') {
      if (playerBucket === 'MID') {
        return 0.7;
      }
      if (playerBucket === 'ATT') {
        return 0.3;
      }
      return 0.1;
    }

    if (bucket === 'MID') {
      if (playerBucket === 'DEF' || playerBucket === 'ATT') {
        return 0.72;
      }
      return 0.08;
    }

    if (playerBucket === 'MID') {
      return 0.72;
    }
    if (playerBucket === 'DEF') {
      return 0.28;
    }
    return 0.08;
  }

  private isGoalkeeperPosition(position?: string): boolean {
    return /(GK|GOAL)/.test((position ?? '').toUpperCase());
  }

  private isDefenderPosition(position?: string): boolean {
    return /(CB|RB|LB|RWB|LWB|DEF|SW|BACK)/.test((position ?? '').toUpperCase());
  }

  private isMidfielderPosition(position?: string): boolean {
    return /(DM|CM|AM|LM|RM|MID|MF)/.test((position ?? '').toUpperCase());
  }

  private isAttackerPosition(position?: string): boolean {
    return /(ST|CF|RW|LW|WF|ATT|FW|SS|FWD)/.test((position ?? '').toUpperCase());
  }

  private playerQualityScore(player: ChemistryXiCandidate): number {
    const averageScore = this.normalizeMetricToTen(player.statistics?.averageScore, 10, 5);
    const bestScore = this.normalizeMetricToTen(player.statistics?.bestScore, 10, averageScore);
    const speed = this.normalizeMetricToTen(player.speed, 100, 5);
    const endurance = this.normalizeMetricToTen(player.endurance, 100, 5);
    const dribbles = this.normalizeMetricToTen(player.dribbles, 20, 5);
    const shots = this.normalizeMetricToTen(player.shots, 20, 5);

    return this.clampScore(
      averageScore * 0.4 +
      bestScore * 0.15 +
      speed * 0.15 +
      endurance * 0.12 +
      dribbles * 0.1 +
      shots * 0.08
    );
  }

  private normalizeMetricToTen(value: unknown, maxValue: number, fallback: number): number {
    const numeric = typeof value === 'number' ? value : Number(value);
    if (!Number.isFinite(numeric)) {
      return this.clampScore(fallback);
    }

    if (numeric <= 10) {
      return this.clampScore(numeric);
    }

    if (maxValue > 10) {
      return this.clampScore((Math.min(numeric, maxValue) / maxValue) * 10);
    }

    return this.clampScore(numeric / 10);
  }

  private async resolveSeasonForGeneration(): Promise<string> {
    const latest = await this.chemistryPairModel.findOne().sort({ season: -1, updatedAt: -1 }).lean().exec();
    if (latest?.season) {
      return latest.season;
    }

    const now = new Date();
    const year = now.getMonth() >= 6 ? now.getFullYear() : now.getFullYear() - 1;
    return `${year}-${year + 1}`;
  }

  private collectUniquePlayerIdsFromPairs(pairs: Array<Pick<ChemistryPair, 'playerAId' | 'playerBId'>>): string[] {
    const ids = new Set<string>();
    for (const pair of pairs) {
      ids.add(String(pair.playerAId));
      ids.add(String(pair.playerBId));
    }
    return Array.from(ids);
  }

  private buildPairKey(playerAId: string, playerBId: string): string {
    const [minId, maxId] = this.normalizePairIds(playerAId, playerBId);
    return `${minId}:${maxId}`;
  }

  private normalizePairIds(playerAId: string, playerBId: string): [string, string] {
    return [playerAId, playerBId].sort((a, b) => a.localeCompare(b)) as [string, string];
  }

  private async assertPlayersExist(playerIds: string[]) {
    const unique = Array.from(new Set(playerIds));
    const players = await this.playerModel.find({ _id: { $in: unique } }).select('_id').lean().exec();
    const found = new Set(players.map((player) => String(player._id)));
    const missing = unique.filter((id) => !found.has(id));

    if (missing.length > 0) {
      throw new BadRequestException(`Unknown player IDs: ${missing.join(', ')}`);
    }
  }

  private async getPlayersByIds(playerIds: string[]): Promise<PlayerLite[]> {
    if (playerIds.length === 0) {
      return [];
    }

    const players = await this.playerModel
      .find({ _id: { $in: playerIds } })
      .select('_id name firstName lastName position')
      .lean()
      .exec();

    return players as PlayerLite[];
  }

  private async getPlayerMapByIds(playerIds: string[]): Promise<Map<string, PlayerLite>> {
    const players = await this.getPlayersByIds(playerIds);
    const map = new Map<string, PlayerLite>();
    for (const player of players) {
      map.set(String(player._id), player);
    }
    return map;
  }

  private getPlayerDisplayName(player: PlayerLite): string {
    if (player.name && player.name.trim().length > 0) {
      return player.name;
    }

    const fullName = `${player.firstName ?? ''} ${player.lastName ?? ''}`.trim();
    if (fullName.length > 0) {
      return fullName;
    }

    return String(player._id);
  }

  private ratingCategory(rating: number): 'excellent' | 'good' | 'neutral' | 'conflict' {
    if (rating >= 8.5) {
      return 'excellent';
    }
    if (rating >= 7) {
      return 'good';
    }
    if (rating <= 4.5) {
      return 'conflict';
    }
    return 'neutral';
  }

  private lineupPairKeys(playerIds: string[]): string[] {
    const keys: string[] = [];
    for (let i = 0; i < playerIds.length; i += 1) {
      for (let j = i + 1; j < playerIds.length; j += 1) {
        keys.push(this.buildPairKey(playerIds[i], playerIds[j]));
      }
    }
    return keys;
  }

  private pairSmartAlert(rating: number | null, positionA?: string, positionB?: string): string | undefined {
    if (rating === null) {
      if (this.isCentralRole(positionA) && this.isCentralRole(positionB)) {
        return 'New central pairing opportunity: no data yet.';
      }
      return 'Pair not tested enough yet.';
    }

    if (rating >= 8.5) {
      return 'High chemistry: keep them close in the same combination zone.';
    }

    if (rating <= 4.5) {
      if (this.shareCorridor(positionA, positionB)) {
        return 'Risk alert: avoid using this pair in the same corridor.';
      }
      return 'Risk alert: this pair often disconnects under pressure.';
    }

    return undefined;
  }

  private shareCorridor(positionA?: string, positionB?: string): boolean {
    if (!positionA || !positionB) {
      return false;
    }

    if (this.isLeftCorridor(positionA) && this.isLeftCorridor(positionB)) {
      return true;
    }

    if (this.isRightCorridor(positionA) && this.isRightCorridor(positionB)) {
      return true;
    }

    return this.isCentralRole(positionA) && this.isCentralRole(positionB);
  }

  private isLeftCorridor(position?: string): boolean {
    if (!position) {
      return false;
    }
    const normalized = position.toUpperCase();
    return normalized.includes('L') || normalized.includes('LEFT');
  }

  private isRightCorridor(position?: string): boolean {
    if (!position) {
      return false;
    }
    const normalized = position.toUpperCase();
    return normalized.includes('R') || normalized.includes('RIGHT');
  }

  private isCentralRole(position?: string): boolean {
    if (!position) {
      return false;
    }
    const normalized = position.toUpperCase();
    return normalized.includes('C') || normalized.includes('CM') || normalized.includes('AM') || normalized.includes('DM');
  }

  private centralTriangleScore(evaluations: PairEvaluation[]) {
    const central = evaluations.filter(
      (item) => this.isCentralRole(item.playerAPosition) && this.isCentralRole(item.playerBPosition) && item.rating !== null
    );

    if (central.length === 0) {
      return {
        label: 'Unknown',
        score: null,
        comment: 'No measured central chemistry yet.'
      };
    }

    const score = Number(
      (central.reduce((sum, item) => sum + (item.rating as number), 0) / central.length).toFixed(2)
    );
    return {
      label: score >= 8 ? 'Excellent' : score >= 6.5 ? 'Stable' : 'Fragile',
      score,
      comment: score >= 8 ? 'Central links are strong.' : 'Central links need work.'
    };
  }

  private defensiveCoreScore(evaluations: PairEvaluation[]) {
    const defensive = evaluations.filter((item) => {
      const a = (item.playerAPosition ?? '').toUpperCase();
      const b = (item.playerBPosition ?? '').toUpperCase();
      const aDef = a.includes('CB') || a.includes('LB') || a.includes('RB') || a.includes('GK');
      const bDef = b.includes('CB') || b.includes('LB') || b.includes('RB') || b.includes('GK');
      return aDef && bDef && item.rating !== null;
    });

    if (defensive.length === 0) {
      return {
        label: 'Unknown',
        score: null,
        comment: 'No measured defensive core chemistry yet.'
      };
    }

    const score = Number(
      (defensive.reduce((sum, item) => sum + (item.rating as number), 0) / defensive.length).toFixed(2)
    );
    return {
      label: score >= 8 ? 'Excellent' : score >= 6.5 ? 'Stable' : 'Fragile',
      score,
      comment: score >= 8 ? 'Defensive line coordination is strong.' : 'Defensive line needs repetitions.'
    };
  }

  private buildLineupSmartAlerts(evaluations: PairEvaluation[]) {
    const alerts: string[] = [];

    const best = evaluations
      .filter((item) => item.rating !== null)
      .sort((a, b) => (b.rating as number) - (a.rating as number))[0];
    if (best && (best.rating as number) >= 8.5) {
      alerts.push(
        `${best.playerAName} + ${best.playerBName} have ${best.rating}/10 chemistry. Keep them in connected zones.`
      );
    }

    const risk = evaluations
      .filter((item) => item.rating !== null)
      .sort((a, b) => (a.rating as number) - (b.rating as number))[0];
    if (risk && (risk.rating as number) <= 4.5) {
      alerts.push(
        `${risk.playerAName} + ${risk.playerBName} are at ${risk.rating}/10. Avoid overloading them in the same lane.`
      );
    }

    const opportunity = evaluations.find(
      (item) => item.rating === null && this.shareCorridor(item.playerAPosition, item.playerBPosition)
    );
    if (opportunity) {
      alerts.push(
        `${opportunity.playerAName} + ${opportunity.playerBName} are not tested enough in their shared zone. Consider a controlled trial.`
      );
    }

    return alerts;
  }

  private async resolveAiInsights(
    context: 'best_pairs' | 'conflicts' | 'lineup' | 'player_network' | 'pair_profile',
    season: string,
    payload: Record<string, unknown>,
    fallbackInsights: string[]
  ): Promise<{ insights: string[]; source: 'ai-service' | 'rule-based'; score?: number }> {
    const aiPayload = {
      context,
      season,
      payload
    };

    const aiResult = await this.aiService.getChemistryInsights(aiPayload);
    const aiInsights = this.extractAiInsights(aiResult);
    const aiScore = this.extractAiScore(aiResult);

    if (aiInsights.length > 0 || typeof aiScore === 'number') {
      const insights = aiInsights.length
        ? aiInsights
        : [`AI computed chemistry score: ${this.clampScore(aiScore as number).toFixed(2)}/10.`];

      return {
        insights,
        source: 'ai-service',
        score: typeof aiScore === 'number' ? this.clampScore(aiScore) : undefined
      };
    }

    return {
      insights: fallbackInsights,
      source: 'rule-based'
    };
  }

  private extractAiInsights(aiResult: unknown): string[] {
    if (!aiResult || typeof aiResult !== 'object') {
      return [];
    }

    const container = aiResult as Record<string, unknown>;
    const candidates: string[] = [];

    const insights = container.insights;
    if (Array.isArray(insights)) {
      for (const item of insights) {
        if (typeof item === 'string' && item.trim().length > 0) {
          candidates.push(item.trim());
        }
      }
    }

    const recommendations = container.recommendations;
    if (Array.isArray(recommendations)) {
      for (const item of recommendations) {
        if (typeof item === 'string' && item.trim().length > 0) {
          candidates.push(item.trim());
        }
      }
    }

    const suggestions = container.suggestions;
    if (Array.isArray(suggestions)) {
      for (const item of suggestions) {
        if (typeof item === 'string' && item.trim().length > 0) {
          candidates.push(item.trim());
        }
      }
    }

    const singleInsight = container.insight;
    if (typeof singleInsight === 'string' && singleInsight.trim().length > 0) {
      candidates.push(singleInsight.trim());
    }

    const message = container.message;
    if (typeof message === 'string' && message.trim().length > 0 && candidates.length === 0) {
      candidates.push(message.trim());
    }

    return Array.from(new Set(candidates));
  }

  private extractAiScore(aiResult: unknown): number | undefined {
    if (!aiResult || typeof aiResult !== 'object') {
      return undefined;
    }

    const container = aiResult as Record<string, unknown>;
    const scoreCandidates = [
      container.score,
      container.chemistryScore,
      container.predictedScore,
      container.compatibilityScore
    ];

    for (const candidate of scoreCandidates) {
      if (typeof candidate === 'number' && Number.isFinite(candidate)) {
        return this.clampScore(candidate);
      }
      if (typeof candidate === 'string') {
        const parsed = Number(candidate);
        if (Number.isFinite(parsed)) {
          return this.clampScore(parsed);
        }
      }
    }

    return undefined;
  }

  private resolvePairScore(pair: ChemistryPair): PairScoreResolution {
    if (typeof pair.manualScore === 'number') {
      return {
        rating: this.clampScore(pair.manualScore),
        source: 'manual'
      };
    }

    if (typeof pair.observationCount === 'number' && pair.observationCount > 0) {
      return {
        rating: this.clampScore(pair.averageRating),
        source: 'observation'
      };
    }

    if (typeof pair.aiScore === 'number') {
      return {
        rating: this.clampScore(pair.aiScore),
        source: 'ai'
      };
    }

    return { rating: null };
  }

  private clampScore(value: number): number {
    if (!Number.isFinite(value)) {
      return 0;
    }
    return Math.max(0, Math.min(10, Number(value.toFixed(2))));
  }

  private extractStyleVector(profile: any): Record<string, number> {
    return {
      possessionPlay: this.clampScore(Number(profile?.possessionPlay ?? 5)),
      selfishness: this.clampScore(Number(profile?.selfishness ?? 5)),
      oneTouchPreference: this.clampScore(Number(profile?.oneTouchPreference ?? 5)),
      directPlay: this.clampScore(Number(profile?.directPlay ?? 5)),
      riskTaking: this.clampScore(Number(profile?.riskTaking ?? 5)),
      pressingIntensity: this.clampScore(Number(profile?.pressingIntensity ?? 5)),
      offBallMovement: this.clampScore(Number(profile?.offBallMovement ?? 5)),
      communication: this.clampScore(Number(profile?.communication ?? 5)),
      defensiveDiscipline: this.clampScore(Number(profile?.defensiveDiscipline ?? 5)),
      creativity: this.clampScore(Number(profile?.creativity ?? 5))
    };
  }

  private computeProfileCompatibilityScore(profileA: any, profileB: any): number {
    const a = this.extractStyleVector(profileA);
    const b = this.extractStyleVector(profileB);

    const similarity = (metric: keyof typeof a) => 10 - Math.abs(a[metric] - b[metric]);
    const complement = (left: number, right: number, targetSum: number) =>
      Math.max(0, 10 - Math.abs(left + right - targetSum));

    const components = [
      { score: similarity('possessionPlay'), weight: 0.18 },
      { score: similarity('oneTouchPreference'), weight: 0.16 },
      { score: similarity('offBallMovement'), weight: 0.14 },
      { score: similarity('communication'), weight: 0.12 },
      { score: similarity('pressingIntensity'), weight: 0.1 },
      { score: similarity('defensiveDiscipline'), weight: 0.1 },
      { score: complement(a.selfishness, b.selfishness, 9), weight: 0.1 },
      { score: complement(a.directPlay, b.directPlay, 12), weight: 0.05 },
      { score: similarity('riskTaking'), weight: 0.03 },
      { score: similarity('creativity'), weight: 0.02 }
    ];

    const weighted = components.reduce((sum, component) => sum + component.score * component.weight, 0);
    return this.clampScore(weighted);
  }

  private buildProfilePairInsights(playerAName: string, playerBName: string, score: number): string[] {
    if (score >= 8.5) {
      return [
        `${playerAName} + ${playerBName} show excellent style compatibility (${score.toFixed(2)}/10).`,
        'Recommendation: keep them in connected zones to maximize fluid combinations.'
      ];
    }

    if (score <= 4.5) {
      return [
        `${playerAName} + ${playerBName} present high style friction (${score.toFixed(2)}/10).`,
        'Recommendation: reduce shared lane usage and define explicit role separation.'
      ];
    }

    return [
      `${playerAName} + ${playerBName} have moderate profile compatibility (${score.toFixed(2)}/10).`,
      'Recommendation: schedule targeted tactical drills to improve automatisms.'
    ];
  }

  private buildAiPairInsights(
    pairs: Array<{ averageRating: number; playerAName: string; playerBName: string }>,
    mode: 'best' | 'conflict'
  ): string[] {
    const weights = this.aiService.getWeights();
    const ratingWeight = weights.performance.rating;

    if (pairs.length === 0) {
      return ['AI: no pair data matched the requested filter.'];
    }

    if (mode === 'best') {
      const first = pairs[0];
      return [
        `AI: prioritize ${first.playerAName} + ${first.playerBName} in repeated patterns; chemistry influence coefficient ${ratingWeight}.`
      ];
    }

    const first = pairs[0];
    return [
      `AI: de-risk ${first.playerAName} + ${first.playerBName} with role separation; chemistry influence coefficient ${ratingWeight}.`
    ];
  }

  private buildAiLineupInsights(score: number, coverage: number, alerts: string[]): string[] {
    const weights = this.aiService.getWeights();
    const guidance: string[] = [];

    if (score < 6.5) {
      guidance.push('AI: lineup chemistry is low, prioritize rehearsed pairings in training micro-cycles.');
    } else if (score >= 8) {
      guidance.push('AI: lineup chemistry is strong, preserve core links and rotate around them.');
    } else {
      guidance.push('AI: lineup chemistry is acceptable, target 1-2 weak links for improvement.');
    }

    if (coverage < 40) {
      guidance.push('AI: data coverage is limited; collect more pair observations before hard decisions.');
    }

    guidance.push(`AI model reference: performance rating weight ${weights.performance.rating}.`);

    if (alerts.length === 0) {
      guidance.push('AI: no specific smart alert detected for this lineup.');
    }

    return guidance;
  }

  private buildAiNetworkInsights(
    connections: Array<{ rating: number | null; teammateName: string }>
  ): string[] {
    const known = connections.filter(
      (connection): connection is { rating: number; teammateName: string } =>
        typeof connection.rating === 'number'
    );

    if (known.length === 0) {
      return ['AI: this player has no chemistry records yet.'];
    }

    const sorted = [...known].sort((a, b) => b.rating - a.rating);
    const strongest = sorted[0];
    const weakest = sorted[sorted.length - 1];

    return [
      `AI: strongest link is ${strongest.teammateName} (${strongest.rating}/10). Build around this duo in key phases.`,
      `AI: weakest link is ${weakest.teammateName} (${weakest.rating}/10). Use staged exposure to improve cohesion.`
    ];
  }

  private async resolveLatestSeason(): Promise<string> {
    const latest = await this.chemistryPairModel.findOne().sort({ season: -1, updatedAt: -1 }).lean().exec();
    if (!latest?.season) {
      throw new BadRequestException('No chemistry data available yet. Provide a season first.');
    }
    return latest.season;
  }

  private async toPairViews(pairs: ChemistryPair[]) {
    const ids = new Set<string>();
    for (const pair of pairs) {
      ids.add(String(pair.playerAId));
      ids.add(String(pair.playerBId));
    }

    const players = await this.getPlayerMapByIds(Array.from(ids));
    return pairs.map((pair) => {
      const playerA = players.get(String(pair.playerAId));
      const playerB = players.get(String(pair.playerBId));
      const effectiveScore = this.resolvePairScore(pair);

      return {
        playerAId: String(pair.playerAId),
        playerAName: playerA ? this.getPlayerDisplayName(playerA) : String(pair.playerAId),
        playerAPosition: playerA?.position,
        playerBId: String(pair.playerBId),
        playerBName: playerB ? this.getPlayerDisplayName(playerB) : String(pair.playerBId),
        playerBPosition: playerB?.position,
        averageRating: pair.averageRating,
        lastRating: pair.lastRating,
        aiScore: pair.aiScore,
        manualScore: pair.manualScore,
        effectiveRating: effectiveScore.rating,
        scoreSource: effectiveScore.source,
        observationCount: pair.observationCount,
        category: effectiveScore.rating !== null ? this.ratingCategory(effectiveScore.rating) : undefined,
        tacticalZone: pair.tacticalZone,
        notes: pair.notes,
        lastObservedAt: pair.lastObservedAt
      };
    });
  }

  private async toPairView(pair: ChemistryPair) {
    const views = await this.toPairViews([pair]);
    return views[0];
  }
}
