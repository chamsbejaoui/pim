import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import { randomUUID } from "crypto";
import { Player } from "../players/schemas/player.schema";
import { MedicalService } from "../medical/medical.service";
import { MedicalRecord } from "../medical/schemas/medical-record.schema";

const POSITIONS = ["GK", "RB", "CB", "LB", "DM", "CM", "AM", "RW", "LW", "ST"];
const FIRST_NAMES = [
  "Liam",
  "Noah",
  "Ethan",
  "Mason",
  "Leo",
  "Julian",
  "Kai",
  "Ryan",
  "Marco",
  "Hugo",
];
const LAST_NAMES = [
  "Rossi",
  "Silva",
  "Khan",
  "Lopez",
  "Novak",
  "Ibrahim",
  "Costa",
  "Meyer",
  "Bennett",
  "Park",
];

type FakePlayer = {
  id: string;
  name: string;
  position: string;
};

type TeamPlayer = Player & { _id: any };

type SimulationMatch = {
  matchId: string;
  teamA: TeamPlayer[];
  teamB: FakePlayer[];
};

@Injectable()
export class SimulationService {
  private readonly matches = new Map<string, SimulationMatch>();

  constructor(
    @InjectModel(Player.name) private readonly playerModel: Model<Player>,
    @InjectModel(MedicalRecord.name)
    private readonly medicalRecordModel: Model<MedicalRecord>,
    private readonly medicalService: MedicalService,
  ) {}

  async getAvailablePlayers() {
    const injuredIds = await this.getInjuredPlayerIds();
    return this.playerModel
      .find({ _id: { $nin: injuredIds }, isInjured: { $ne: true } })
      .lean()
      .exec();
  }

  async startMatch(playerIds?: string[]) {
    const hasManualSelection = Array.isArray(playerIds) && playerIds.length > 0;

    if (hasManualSelection && playerIds!.length !== 11) {
      throw new BadRequestException("Select exactly 11 players");
    }

    const injuredIds = await this.getInjuredPlayerIds();

    const teamA = hasManualSelection
      ? ((await this.playerModel
          .find({ _id: { $in: playerIds } })
          .lean()
          .exec()) as TeamPlayer[])
      : ((await this.playerModel
          .aggregate([
            { $match: { _id: { $nin: injuredIds } } },
            { $sample: { size: 11 } },
          ])
          .exec()) as TeamPlayer[]);

    if (!teamA || teamA.length < 11) {
      throw new BadRequestException("Not enough players to start simulation");
    }

    if (hasManualSelection && teamA.length !== 11) {
      throw new BadRequestException("Select exactly 11 players");
    }

    if (hasManualSelection) {
      const injuredSelected = teamA.find((player) =>
        injuredIds.some((id) => id.toString() === player._id.toString()),
      );

      if (injuredSelected) {
        throw new BadRequestException(
          "One or more selected players are currently injured",
        );
      }
    }

    const teamB = this.createFakeTeam(11);
    const matchId = randomUUID();

    this.matches.set(matchId, {
      matchId,
      teamA,
      teamB,
    });

    return { matchId, teamA, teamB };
  }

  async endMatch(matchId: string) {
    const match = this.matches.get(matchId);
    if (!match) {
      throw new NotFoundException("Match not found");
    }

    try {
      type MatchResult = {
        playerId: string;
        name: string;
        fatigue: number;
        load: number;
        injuryProbability: number;
        status: string;
        injuryType: string | null;
        recoveryDays: number | null;
        severity: string | null;
        playedMatch: boolean;
        playedAt: string;
      };

      type InternalMatchResult = MatchResult & { _playerObjectId: any };

      const results: MatchResult[] = [];

      const baseResults: InternalMatchResult[] = [];
      const statsByPlayer = match.teamA.map((player) => ({
        player,
        stats: this.generateMatchStats(),
      }));

      const aiResults = await this.medicalService.analyzePlayersBatch(
        statsByPlayer.map(({ player, stats }) => ({
          playerId: player._id.toString(),
          fatigue: stats.fatigue,
          minutes: stats.minutes,
          load: stats.load,
        })),
      );

      for (const { player, stats } of statsByPlayer) {
        const aiResult = aiResults.get(player._id.toString());
        if (!aiResult) {
          throw new InternalServerErrorException("Missing AI result");
        }

        const playedAt = new Date();
        const status = this.mapStatus(
          aiResult.injured,
          aiResult.injuryProbability,
        );

        await this.playerModel.updateOne(
          { _id: player._id },
          {
            $set: {
              lastMatchId: matchId,
              lastMatchAt: playedAt,
              lastMatchLoad: stats.load,
              lastMatchFatigue: stats.fatigue,
              lastMatchInjuryProbability: aiResult.injuryProbability,
              isInjured: aiResult.injured,
              lastInjuryType: aiResult.injuryType ?? "Unknown",
              lastRecoveryDays: aiResult.recoveryDays ?? 0,
              lastSeverity: aiResult.severity ?? "Mild",
              lastInjuryProbability: aiResult.injuryProbability,
            },
          },
        );

        baseResults.push({
          playerId: player._id.toString(),
          name: this.playerDisplayName(player),
          fatigue: stats.fatigue,
          load: stats.load,
          injuryProbability: aiResult.injuryProbability,
          status,
          injuryType: aiResult.injuryType,
          recoveryDays: aiResult.recoveryDays,
          severity: aiResult.severity,
          playedMatch: true,
          playedAt: playedAt.toISOString(),
          _playerObjectId: player._id,
        } as InternalMatchResult);
      }

      const hasInjury = baseResults.some((item) => item.status === "INJURED");
      if (!hasInjury && baseResults.length > 0) {
        const sorted = [...baseResults].sort(
          (a, b) => b.injuryProbability - a.injuryProbability,
        );
        const target = sorted[0];
        const forcedStats = { fatigue: 100, minutes: 90, load: 100 };
        let forcedResult = await this.medicalService.analyzePlayer(
          target.playerId,
          forcedStats,
        );

        if (!forcedResult.injured) {
          const forcedProbability = Math.max(0.85, forcedResult.injuryProbability);
          const forcedType = forcedResult.injuryType ?? "Muscle strain";
          const forcedSeverity = forcedResult.severity ?? "High";
          const forcedRecovery = forcedResult.recoveryDays ?? 14;

          await this.medicalRecordModel.create({
            playerId: target._playerObjectId,
            injuryProbability: forcedProbability,
            injured: true,
            injuryType: forcedType,
            recoveryDays: forcedRecovery,
            severity: forcedSeverity,
            rehab: forcedResult.rehab ?? [],
            prevention: forcedResult.prevention ?? [],
            warning: forcedResult.warning ?? "High injury risk",
          });

          forcedResult = {
            ...forcedResult,
            injured: true,
            injuryProbability: forcedProbability,
            injuryType: forcedType,
            recoveryDays: forcedRecovery,
            severity: forcedSeverity,
          };
        }

        await this.playerModel.updateOne(
          { _id: target._playerObjectId },
          {
            $set: {
              isInjured: true,
              lastInjuryType: forcedResult.injuryType ?? "Unknown",
              lastRecoveryDays: forcedResult.recoveryDays ?? 0,
              lastSeverity: forcedResult.severity ?? "Mild",
              lastInjuryProbability: forcedResult.injuryProbability,
              lastMatchInjuryProbability: forcedResult.injuryProbability,
            },
          },
        );

        const index = baseResults.findIndex(
          (item) => item.playerId === target.playerId,
        );
        if (index >= 0) {
          baseResults[index] = {
            ...baseResults[index],
            injuryProbability: forcedResult.injuryProbability,
            status: "INJURED",
            injuryType: forcedResult.injuryType,
            recoveryDays: forcedResult.recoveryDays,
            severity: forcedResult.severity,
          };
        }
      }

      baseResults.forEach(({ _playerObjectId, ...rest }) => results.push(rest));

      this.matches.delete(matchId);
      return results;
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new InternalServerErrorException("Simulation end failed");
    }
  }

  private async getInjuredPlayerIds() {
    const latest = await this.medicalRecordModel
      .aggregate([
        { $sort: { createdAt: -1 } },
        {
          $group: {
            _id: "$playerId",
            injured: { $first: "$injured" },
          },
        },
        { $match: { injured: true } },
      ])
      .exec();

    return latest.map((record) => record._id);
  }

  private createFakeTeam(size: number): FakePlayer[] {
    return Array.from({ length: size }).map(() => {
      const first = this.pickRandom(FIRST_NAMES);
      const last = this.pickRandom(LAST_NAMES);
      return {
        id: randomUUID(),
        name: `${first} ${last}`,
        position: this.pickRandom(POSITIONS),
      };
    });
  }

  private playerDisplayName(player: any) {
    const name = (player?.name ?? "").toString().trim();
    if (name) {
      return name;
    }
    const fullName = (player?.fullName ?? "").toString().trim();
    if (fullName) {
      return fullName;
    }
    const playerName = (player?.playerName ?? "").toString().trim();
    if (playerName) {
      return playerName;
    }
    const providerId = (player?.providerPlayerId ?? "").toString().trim();
    if (providerId) {
      return providerId;
    }
    return "Unknown";
  }

  private generateMatchStats() {
    const minutes = 90;
    const baseLoad = this.randomInt(40, 100);
    const baseFatigue = this.randomInt(30, 100);

    const events = {
      highIntensity: Math.random() < 0.3,
      collision: Math.random() < 0.25,
      sprintBurst: Math.random() < 0.4,
    };

    let load = baseLoad;
    let fatigue = Math.round(baseFatigue * (0.6 + load / 160));
    let sprints = this.randomInt(10, 35);
    let collisions = this.randomInt(0, 6);
    let distanceCovered = this.randomInt(8500, 11500);

    if (events.highIntensity) {
      load += this.randomInt(8, 18);
      fatigue += this.randomInt(6, 12);
      distanceCovered += this.randomInt(200, 500);
    }

    if (events.collision) {
      collisions += this.randomInt(1, 3);
      fatigue += this.randomInt(3, 8);
    }

    if (events.sprintBurst) {
      sprints += this.randomInt(4, 10);
      load += this.randomInt(5, 12);
    }

    load = Math.min(100, load);
    fatigue = Math.min(100, Math.max(30, fatigue));

    return {
      minutes,
      load,
      fatigue,
      distanceCovered,
      sprints,
      collisions,
    };
  }

  private mapStatus(injured: boolean, probability: number) {
    if (injured) {
      return "INJURED";
    }
    if (probability >= 0.4) {
      return "WARNING";
    }
    return "SAFE";
  }

  private pickRandom<T>(items: T[]) {
    return items[Math.floor(Math.random() * items.length)];
  }

  private randomInt(min: number, max: number) {
    const lower = Math.ceil(min);
    const upper = Math.floor(max);
    return Math.floor(Math.random() * (upper - lower + 1)) + lower;
  }
}
