import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import axios from 'axios';
import { Player } from '../players/schemas/player.schema';
import { Squad, SquadDocument } from '../squad/schemas/squad.schema';
import { AnalyzeOpponentDto, OpponentPlayerDto } from './dto/analyze-opponent.dto';

type AvailablePlayer = {
  id: string;
  name: string;
  position: string;
  rating: number;
};

type PositionBucket = 'GK' | 'DEF' | 'MID' | 'ATT' | 'OTHER';

type PositionSummary = {
  count: number;
  averageRating: number;
  totalGoals: number;
  totalAssists: number;
  totalShots: number;
  totalPasses: number;
  totalTackles: number;
};

type NormalizedOpponentInput = {
  opponentStyle: string;
  opponentTeamName: string;
  preferredFormation?: string;
  strengths: string[];
  weaknesses: string[];
  opponentSquad: OpponentPlayerDto[];
};

type LegacyStartingXiPlayer = {
  player_id: string;
  player_name: string;
  role: string;
  role_label: string;
  x: number;
  y: number;
  instruction: string;
  actions_cles: string[];
  joueur_adverse_a_surveiller?: string;
};

type LegacyTacticalPlan = {
  formation: string;
  formation_justification: string;
  instructions: string;
  strengths: string[];
  weaknesses: string[];
  danger_principal?: string;
  bloc_defensif?: string;
  pressing_trigger?: string;
  axe_offensif?: string;
  consignes_collectives: {
    phases_defensives: string[];
    phases_offensives: string[];
    transitions_offensives: string[];
    transitions_defensives: string[];
  };
  phases_arretees: {
    corners_pour: string;
    corners_contre: string;
    coups_francs_pour: string;
    coups_francs_contre: string;
  };
  variantes_selon_score: {
    si_on_mene: string;
    si_egalite: string;
    si_on_perd: string;
  };
  message_vestiaire: string;
  starting_xi: LegacyStartingXiPlayer[];
};

@Injectable()
export class TacticsService {
  private readonly logger = new Logger(TacticsService.name);
  private readonly aiBaseUrl = process.env.AI_SERVICE_URL || 'http://localhost:8000';

  constructor(
    @InjectModel(Player.name) private readonly playerModel: Model<Player>,
    @InjectModel(Squad.name) private readonly squadModel: Model<SquadDocument>
  ) {}

  async suggestFormation(dto: AnalyzeOpponentDto) {
    const squad = await this.resolveSquad(dto.season);
    const squadPlayerIds = (squad.playerIds || []).map((id) => String(id));

    const players = await this.playerModel
      .find({
        _id: { $in: squadPlayerIds },
        isInjured: { $ne: true },
        $or: [{ status: 'active' }, { status: { $exists: false } }]
      })
      .exec();

    const playerById = new Map(players.map((player: any) => [String(player._id), player]));
    const orderedPlayers = squadPlayerIds
      .map((id) => playerById.get(id))
      .filter((player): player is any => !!player);

    const availablePlayers: AvailablePlayer[] = orderedPlayers.map((p) => ({
      id: (p as any)._id?.toString() || '',
      name: `${p.firstName || ''} ${p.lastName || ''}`.trim() || p.name || 'Unknown',
      position: p.position || 'CM',
      rating: p.statistics?.averageScore || 50
    }));

    if (availablePlayers.length === 0) {
      throw new BadRequestException(
        `No active and non-injured players available in squad for season ${squad.season}.`
      );
    }

    if (availablePlayers.length < 11) {
      throw new BadRequestException(
        `Squad season ${squad.season} has only ${availablePlayers.length} active/non-injured players. At least 11 are required.`
      );
    }

    const input = this.normalizeInput(dto);
    const positionSummary = this.buildPositionSummary(input.opponentSquad);
    const keyPlayers = this.rankKeyPlayers(input.opponentSquad).slice(0, 5);
    const tacticalFocus = this.buildTacticalFocus(input, positionSummary, keyPlayers);
    const aiRecommendation = await this.fetchAiRecommendation(
      input,
      availablePlayers,
      positionSummary,
      keyPlayers,
      tacticalFocus
    );
    const legacyPlan = this.buildLegacyPlan(
      input,
      availablePlayers,
      tacticalFocus,
      keyPlayers,
      aiRecommendation
    );

    return {
      ...legacyPlan,
      opponent: {
        teamName: input.opponentTeamName,
        style: input.opponentStyle,
        preferredFormation: input.preferredFormation || null,
        strengths: input.strengths,
        weaknesses: input.weaknesses,
        squadSize: input.opponentSquad.length
      },
      summaryByPosition: positionSummary,
      keyPlayers,
      tacticalFocus,
      aiRecommendation,
      analysis: {
        aiSource: aiRecommendation.source,
        summaryByPosition: positionSummary,
        keyPlayers,
        tacticalFocus
      },
      realism: {
        hasRealOpponentSquad: input.opponentSquad.length > 0,
        hasIndividualPlayerStats: input.opponentSquad.some((p) => !!p.stats),
        hasDeclaredStrengths: input.strengths.length > 0,
        hasDeclaredWeaknesses: input.weaknesses.length > 0
      }
    };
  }

  private normalizeInput(dto: AnalyzeOpponentDto): NormalizedOpponentInput {
    const strengths = this.uniqueList(dto.strengths);
    const weaknesses = this.uniqueList(dto.weaknesses);

    const opponentSquad = (dto.opponentSquad || []).map((player) => ({
      ...player,
      name: player.name.trim(),
      position: player.position.trim().toUpperCase(),
      status: player.status?.trim().toLowerCase() || 'starter',
      rating: player.rating ?? player.stats?.rating
    }));

    const inferredStyle = this.inferStyle(strengths, opponentSquad);

    return {
      opponentStyle: (dto.opponentStyle || inferredStyle).trim(),
      opponentTeamName: (dto.opponentTeamName || 'Adversaire').trim(),
      preferredFormation: dto.preferredFormation?.trim(),
      strengths,
      weaknesses,
      opponentSquad
    };
  }

  private async resolveSquad(season?: string): Promise<SquadDocument> {
    const normalizedSeason = season?.trim();

    let squad: SquadDocument | null;
    if (normalizedSeason) {
      squad = await this.squadModel.findOne({ season: normalizedSeason }).exec();
      if (!squad) {
        throw new BadRequestException(
          `No squad found for season "${normalizedSeason}". Configure squad first.`
        );
      }
      return squad;
    }

    squad = await this.squadModel.findOne().sort({ season: -1, createdAt: -1 }).exec();
    if (!squad) {
      throw new BadRequestException('No squad found. Create a season squad before tactical analysis.');
    }

    return squad;
  }

  private uniqueList(values?: string[]): string[] {
    if (!values) {
      return [];
    }
    const normalized = values.map((value) => value.trim()).filter((value) => value.length > 0);
    return [...new Set(normalized)];
  }

  private inferStyle(strengths: string[], opponentSquad: OpponentPlayerDto[]): string {
    const joinedStrengths = strengths.join(' ').toLowerCase();
    if (joinedStrengths.includes('press')) {
      return 'high pressing';
    }
    if (joinedStrengths.includes('transition') || joinedStrengths.includes('contre')) {
      return 'transition';
    }
    if (joinedStrengths.includes('possession')) {
      return 'possession';
    }

    const quickPlayers = opponentSquad.filter((player) => {
      const position = player.position.toUpperCase();
      return position.includes('RW') || position.includes('LW') || position.includes('ST');
    }).length;
    if (quickPlayers >= 4) {
      return 'direct transition';
    }

    return 'balanced';
  }

  private buildPositionSummary(opponentSquad: OpponentPlayerDto[]): Record<PositionBucket, PositionSummary> {
    const baseSummary = (): PositionSummary => ({
      count: 0,
      averageRating: 0,
      totalGoals: 0,
      totalAssists: 0,
      totalShots: 0,
      totalPasses: 0,
      totalTackles: 0
    });

    const summary: Record<PositionBucket, PositionSummary> = {
      GK: baseSummary(),
      DEF: baseSummary(),
      MID: baseSummary(),
      ATT: baseSummary(),
      OTHER: baseSummary()
    };

    for (const player of opponentSquad) {
      const bucket = this.getPositionBucket(player.position);
      const row = summary[bucket];
      row.count += 1;
      row.averageRating += player.rating ?? player.stats?.rating ?? 0;
      row.totalGoals += player.stats?.goals ?? 0;
      row.totalAssists += player.stats?.assists ?? 0;
      row.totalShots += player.stats?.shots ?? 0;
      row.totalPasses += player.stats?.passes ?? 0;
      row.totalTackles += player.stats?.tackles ?? 0;
    }

    (Object.keys(summary) as PositionBucket[]).forEach((bucket) => {
      const row = summary[bucket];
      row.averageRating = row.count > 0 ? Number((row.averageRating / row.count).toFixed(2)) : 0;
    });

    return summary;
  }

  private getPositionBucket(position: string): PositionBucket {
    const value = position.toUpperCase();
    if (value.includes('GK')) {
      return 'GK';
    }
    if (/(CB|RB|LB|RWB|LWB|DEF|SW)/.test(value)) {
      return 'DEF';
    }
    if (/(DM|CM|AM|LM|RM|MID)/.test(value)) {
      return 'MID';
    }
    if (/(ST|CF|RW|LW|WF|ATT|FW)/.test(value)) {
      return 'ATT';
    }
    return 'OTHER';
  }

  private rankKeyPlayers(opponentSquad: OpponentPlayerDto[]) {
    return opponentSquad
      .map((player) => ({
        name: player.name,
        position: player.position,
        status: player.status || 'starter',
        rating: player.rating ?? player.stats?.rating ?? 0,
        stats: player.stats || {},
        threatScore: this.computeThreatScore(player)
      }))
      .sort((a, b) => b.threatScore - a.threatScore);
  }

  private computeThreatScore(player: OpponentPlayerDto): number {
    const stats = player.stats || {};
    const rating = (player.rating ?? stats.rating ?? 6.5) * 10;
    const goals = stats.goals ?? 0;
    const assists = stats.assists ?? 0;
    const shots = stats.shots ?? 0;
    const passes = stats.passes ?? 0;
    const tackles = stats.tackles ?? 0;

    const score = rating * 0.4 + goals * 3 + assists * 2 + shots * 0.2 + passes * 0.01 + tackles * 0.15;
    return Number(score.toFixed(2));
  }

  private buildTacticalFocus(
    input: NormalizedOpponentInput,
    summary: Record<PositionBucket, PositionSummary>,
    keyPlayers: Array<{ name: string; position: string }>
  ): string[] {
    const recommendations: string[] = [];
    const style = input.opponentStyle.toLowerCase();

    if (style.includes('press')) {
      recommendations.push('Sortir du pressing avec un double pivot et des renversements rapides.');
    }
    if (style.includes('possession')) {
        recommendations.push('Bloquer l axe central et forcer l adversaire a jouer cote faible.');
    }
    if (style.includes('transition') || style.includes('contre') || style.includes('counter')) {
        recommendations.push('Securiser la perte de balle avec une structure de rest-defense a 3+2.');
    }

    if (summary.ATT.totalGoals >= Math.max(summary.MID.totalGoals, 10)) {
      recommendations.push('Prioriser le marquage des attaquants adverses dans la surface.');
    }
    if (summary.DEF.averageRating < 6.8 && summary.DEF.count > 0) {
      recommendations.push('Presser haut sur la premiere relance pour provoquer des erreurs defensives.');
    }

    const weaknessText = input.weaknesses.join(' ').toLowerCase();
    if (weaknessText.includes('cpa') || weaknessText.includes('arrete')) {
      recommendations.push('Travailler les coups de pied arretes offensifs pour cibler leur faiblesse.');
    }
    if (weaknessText.includes('lateral') || weaknessText.includes('lateraux')) {
      recommendations.push('Attaquer rapidement les couloirs derriere leurs lateraux.');
    }

    if (keyPlayers.length > 0) {
      recommendations.push(`Prevoir une surveillance specifique pour ${keyPlayers[0].name} (${keyPlayers[0].position}).`);
    }

    if (recommendations.length === 0) {
      recommendations.push('Maintenir un bloc median compact et accelerer sur les transitions offensives.');
    }

    return recommendations.slice(0, 6);
  }

  private buildLegacyPlan(
    input: NormalizedOpponentInput,
    availablePlayers: AvailablePlayer[],
    tacticalFocus: string[],
    keyPlayers: Array<{ name: string; position: string }>,
    aiRecommendation: any
  ): LegacyTacticalPlan {
    const aiPlan = this.extractAiPlanShape(aiRecommendation);

    const formation = this.pickString(
      [
        aiPlan.formation,
        aiPlan.recommended_formation,
        aiPlan.suggested_formation,
        input.preferredFormation,
        this.guessFormationFromStyle(input.opponentStyle)
      ],
      '4-3-3'
    );

    const strengths = this.pickStringArray([aiPlan.strengths, input.strengths], tacticalFocus.slice(0, 3));
    const weaknesses = this.pickStringArray([aiPlan.weaknesses, input.weaknesses], []);

    const startingXi = this.pickStartingXi(aiPlan.starting_xi, availablePlayers, formation, keyPlayers);

    return {
      formation,
      formation_justification: this.pickString(
        [
          aiPlan.formation_justification,
          `Formation choisie pour contrer le style ${input.opponentStyle} de ${input.opponentTeamName}.`
        ],
        ''
      ),
      instructions: this.pickString(
        [aiPlan.instructions, tacticalFocus.join(' ')],
        'Bloc compact et transitions rapides avec discipline tactique.'
      ),
      strengths,
      weaknesses,
      danger_principal: this.pickString(
        [aiPlan.danger_principal, keyPlayers[0]?.name],
        undefined
      ),
      bloc_defensif: this.pickString(
        [aiPlan.bloc_defensif],
        input.opponentStyle.toLowerCase().includes('press') ? 'Bloc medium-bas compact' : 'Bloc medium'
      ),
      pressing_trigger: this.pickString(
        [aiPlan.pressing_trigger],
        'Declencher le pressing sur passe laterale vers leur cote faible.'
      ),
      axe_offensif: this.pickString(
        [aiPlan.axe_offensif],
        'Attaquer les espaces derriere les lateraux et finir dans la surface.'
      ),
      consignes_collectives: {
        phases_defensives: this.pickStringArray(
          [aiPlan.consignes_collectives?.phases_defensives],
          ['Bloc compact entre les lignes', 'Protection de l axe central']
        ),
        phases_offensives: this.pickStringArray(
          [aiPlan.consignes_collectives?.phases_offensives],
          ['Fixer et renverser vite', 'Occuper les demi-espaces']
        ),
        transitions_offensives: this.pickStringArray(
          [aiPlan.consignes_collectives?.transitions_offensives],
          ['Projection rapide apres recuperation']
        ),
        transitions_defensives: this.pickStringArray(
          [aiPlan.consignes_collectives?.transitions_defensives],
          ['Rest-defense 3+2 apres perte de balle']
        )
      },
      phases_arretees: {
        corners_pour: this.pickString(
          [aiPlan.phases_arretees?.corners_pour],
          'Chercher le second poteau avec ecran sur le premier defenseur.'
        ),
        corners_contre: this.pickString(
          [aiPlan.phases_arretees?.corners_contre],
          'Marquage mixte avec protection de la zone 6m.'
        ),
        coups_francs_pour: this.pickString(
          [aiPlan.phases_arretees?.coups_francs_pour],
          'Combinaisons courtes pour creer un tir axe.'
        ),
        coups_francs_contre: this.pickString(
          [aiPlan.phases_arretees?.coups_francs_contre],
          'Ligne bien alignee et seconde balle immediate.'
        )
      },
      variantes_selon_score: {
        si_on_mene: this.pickString(
          [aiPlan.variantes_selon_score?.si_on_mene],
          'Passer en bloc plus bas, conserver la largeur en transition.'
        ),
        si_egalite: this.pickString(
          [aiPlan.variantes_selon_score?.si_egalite],
          'Maintenir l equilibre, augmenter l intensite du contre-pressing.'
        ),
        si_on_perd: this.pickString(
          [aiPlan.variantes_selon_score?.si_on_perd],
          'Augmenter le pressing et ajouter un profil offensif entre les lignes.'
        )
      },
      message_vestiaire: this.pickString(
        [aiPlan.message_vestiaire],
        `Concentration maximale: discipline sans ballon et agressivite controlee contre ${input.opponentTeamName}.`
      ),
      starting_xi: startingXi
    };
  }

  private extractAiPlanShape(aiRecommendation: any): any {
    const candidates = [
      aiRecommendation,
      aiRecommendation?.data,
      aiRecommendation?.plan,
      aiRecommendation?.recommendation,
      aiRecommendation?.result,
      aiRecommendation?.analysis
    ].filter((item) => !!item);

    for (const candidate of candidates) {
      if (candidate.formation || candidate.starting_xi || candidate.instructions) {
        return candidate;
      }
    }

    return aiRecommendation || {};
  }

  private pickString(values: Array<string | undefined>, fallback?: string): string {
    for (const value of values) {
      if (typeof value === 'string' && value.trim().length > 0) {
        return value.trim();
      }
    }
    return fallback || '';
  }

  private pickStringArray(values: Array<string[] | undefined>, fallback: string[]): string[] {
    for (const value of values) {
      if (Array.isArray(value) && value.length > 0) {
        return value.map((item) => String(item));
      }
    }
    return fallback;
  }

  private guessFormationFromStyle(opponentStyle: string): string {
    const style = opponentStyle.toLowerCase();
    if (style.includes('press')) {
      return '4-2-3-1';
    }
    if (style.includes('counter') || style.includes('transition')) {
      return '4-3-3';
    }
    if (style.includes('park') || style.includes('low block')) {
      return '3-5-2';
    }
    return '4-3-3';
  }

  private pickStartingXi(
    aiStartingXi: any,
    availablePlayers: AvailablePlayer[],
    formation: string,
    keyPlayers: Array<{ name: string }>
  ): LegacyStartingXiPlayer[] {
    if (Array.isArray(aiStartingXi) && aiStartingXi.length > 0) {
      const availableById = new Map(availablePlayers.map((player) => [player.id, player]));
      const availableByName = new Map(
        availablePlayers.map((player) => [this.normalizePlayerName(player.name), player])
      );
      const used = new Set<string>();
      const xi: LegacyStartingXiPlayer[] = [];

      for (const raw of aiStartingXi.slice(0, 11)) {
        const rawId = String(raw?.player_id ?? raw?.id ?? '').trim();
        const rawName = String(raw?.player_name ?? raw?.name ?? '').trim();
        const byId = rawId ? availableById.get(rawId) : undefined;
        const byName = rawName ? availableByName.get(this.normalizePlayerName(rawName)) : undefined;
        const selected = byId || byName;

        if (!selected || used.has(selected.id)) {
          continue;
        }

        used.add(selected.id);
        xi.push({
          player_id: selected.id,
          player_name: selected.name,
          role: String(raw?.role ?? 'UKN'),
          role_label: String(raw?.role_label ?? ''),
          x: Number(raw?.x ?? 0.5),
          y: Number(raw?.y ?? 0.5),
          instruction: String(raw?.instruction ?? 'Respecter les principes collectifs.'),
          actions_cles: Array.isArray(raw?.actions_cles)
            ? raw.actions_cles.map((item: any) => String(item))
            : [],
          joueur_adverse_a_surveiller: raw?.joueur_adverse_a_surveiller
            ? String(raw.joueur_adverse_a_surveiller)
            : keyPlayers[0]?.name
        });
      }

      if (xi.length === 11) {
        return xi;
      }

      const fallback = this.buildHeuristicStartingXi(availablePlayers, formation, keyPlayers[0]?.name)
        .filter((player) => !used.has(player.player_id));

      for (const player of fallback) {
        if (xi.length >= 11) {
          break;
        }
        xi.push(player);
      }

      if (xi.length > 0) {
        return xi.slice(0, 11);
      }
    }

    return this.buildHeuristicStartingXi(availablePlayers, formation, keyPlayers[0]?.name);
  }

  private normalizePlayerName(value: string): string {
    return value
      .toLowerCase()
      .normalize('NFKD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9 ]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  private buildHeuristicStartingXi(
    availablePlayers: AvailablePlayer[],
    formation: string,
    dangerPlayerName?: string
  ): LegacyStartingXiPlayer[] {
    const normalized = availablePlayers
      .filter((player) => !!player.id)
      .sort((a, b) => b.rating - a.rating);

    const gks = normalized.filter((player) => this.isGoalkeeper(player.position));
    const defs = normalized.filter((player) => this.isDefender(player.position));
    const mids = normalized.filter((player) => this.isMidfielder(player.position));
    const atts = normalized.filter((player) => this.isAttacker(player.position));
    const others = normalized.filter(
      (player) =>
        !this.isGoalkeeper(player.position) &&
        !this.isDefender(player.position) &&
        !this.isMidfielder(player.position) &&
        !this.isAttacker(player.position)
    );

    const used = new Set<string>();
    const take = (pool: AvailablePlayer[], fallbackPools: AvailablePlayer[][]): AvailablePlayer | null => {
      for (const player of pool) {
        if (!used.has(player.id)) {
          used.add(player.id);
          return player;
        }
      }
      for (const fallbackPool of fallbackPools) {
        for (const player of fallbackPool) {
          if (!used.has(player.id)) {
            used.add(player.id);
            return player;
          }
        }
      }
      return null;
    };

    const parsed = formation
      .split('-')
      .map((value) => Number(value))
      .filter((value) => Number.isFinite(value) && value > 0);
    const lines = parsed.length >= 3 ? parsed : [4, 3, 3];

    const startingXi: LegacyStartingXiPlayer[] = [];

    const gk = take(gks, [defs, mids, atts, others, normalized]);
    if (gk) {
      startingXi.push(this.toXiPlayer(gk, 'GK', 0.5, 0.92, 'Gardien', dangerPlayerName));
    }

    const lineY = this.computeLineY(lines.length);
    lines.forEach((count, lineIndex) => {
      const y = lineY[lineIndex];
      const roleBase = lineIndex === 0 ? 'DEF' : lineIndex === lines.length - 1 ? 'ATT' : 'MID';
      const xPositions = this.computeXPositions(count);

      for (let i = 0; i < count; i += 1) {
        let player: AvailablePlayer | null = null;
        if (roleBase === 'DEF') {
          player = take(defs, [mids, atts, others, normalized]);
        } else if (roleBase === 'MID') {
          player = take(mids, [defs, atts, others, normalized]);
        } else {
          player = take(atts, [mids, defs, others, normalized]);
        }

        if (!player) {
          continue;
        }

        const role = roleBase === 'DEF' ? `D${i + 1}` : roleBase === 'MID' ? `M${i + 1}` : `A${i + 1}`;
        const roleLabel = roleBase === 'DEF' ? 'Defenseur' : roleBase === 'MID' ? 'Milieu' : 'Attaquant';
        startingXi.push(this.toXiPlayer(player, role, xPositions[i], y, roleLabel, dangerPlayerName));
      }
    });

    return startingXi.slice(0, 11);
  }

  private toXiPlayer(
    player: AvailablePlayer,
    role: string,
    x: number,
    y: number,
    roleLabel: string,
    dangerPlayerName?: string
  ): LegacyStartingXiPlayer {
    return {
      player_id: player.id,
      player_name: player.name,
      role,
      role_label: roleLabel,
      x: Number(x.toFixed(3)),
      y: Number(y.toFixed(3)),
      instruction: 'Appliquer la discipline tactique et rester connecte au bloc.',
      actions_cles: ['Respecter les distances de couverture', 'Communiquer a chaque transition'],
      joueur_adverse_a_surveiller: dangerPlayerName
    };
  }

  private computeXPositions(count: number): number[] {
    if (count <= 1) {
      return [0.5];
    }
    const spacing = 0.8 / (count - 1);
    return Array.from({ length: count }, (_, index) => 0.1 + spacing * index);
  }

  private computeLineY(lines: number): number[] {
    if (lines <= 1) {
      return [0.6];
    }
    const minY = 0.18;
    const maxY = 0.76;
    const spacing = (maxY - minY) / (lines - 1);
    return Array.from({ length: lines }, (_, index) => minY + spacing * index);
  }

  private isGoalkeeper(position: string): boolean {
    return position.toUpperCase().includes('GK');
  }

  private isDefender(position: string): boolean {
    return /(CB|RB|LB|RWB|LWB|DEF|SW)/.test(position.toUpperCase());
  }

  private isMidfielder(position: string): boolean {
    return /(DM|CM|AM|LM|RM|MID)/.test(position.toUpperCase());
  }

  private isAttacker(position: string): boolean {
    return /(ST|CF|RW|LW|WF|ATT|FW)/.test(position.toUpperCase());
  }

  private async fetchAiRecommendation(
    input: NormalizedOpponentInput,
    availablePlayers: AvailablePlayer[],
    summaryByPosition: Record<PositionBucket, PositionSummary>,
    keyPlayers: Array<{ name: string; position: string; threatScore: number }>,
    tacticalFocus: string[]
  ) {
    const advancedPayload = {
      opponent_style: input.opponentStyle,
      available_players: availablePlayers,
      opponent_report: {
        team_name: input.opponentTeamName,
        preferred_formation: input.preferredFormation || null,
        strengths: input.strengths,
        weaknesses: input.weaknesses,
        summary_by_position: summaryByPosition,
        key_players: keyPlayers,
        tactical_focus: tacticalFocus,
        squad: input.opponentSquad
      }
    };

    try {
      const advanced = await axios.post(
        `${this.aiBaseUrl}/tactics/analyze-opponent-report`,
        advancedPayload
      );
      return {
        source: 'ai-advanced',
        ...advanced.data
      };
    } catch (advancedError: any) {
      this.logger.warn(
        `Advanced opponent analysis endpoint unavailable. Falling back to suggest-formation: ${advancedError.message}`
      );
    }

    try {
      const fallback = await axios.post(`${this.aiBaseUrl}/tactics/suggest-formation`, {
        opponent_style: input.opponentStyle,
        available_players: availablePlayers
      });
      return {
        source: 'ai-fallback',
        ...fallback.data
      };
    } catch (fallbackError: any) {
      this.logger.warn(`Fallback tactic endpoint unavailable: ${fallbackError.message}`);
      return {
        source: 'heuristic-only',
        message: 'AI tactical engine unavailable, returned deterministic analysis only.'
      };
    }
  }
}
