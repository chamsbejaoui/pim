import {
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from "@nestjs/common";
import { spawn } from "child_process";
import { dirname } from "path";
import { InjectModel } from "@nestjs/mongoose";
import { ConfigService } from "@nestjs/config";
import { Model, Types } from "mongoose";
import { Player } from "../players/schemas/player.schema";
import { MedicalRecord } from "./schemas/medical-record.schema";

type MedicalAiResult = {
  injuryProbability: number;
  injured: boolean;
  injuryType: string | null;
  recoveryDays: number | null;
  severity: string | null;
  rehab: string[];
  prevention: string[];
  warning: string;
  playerId?: string;
};

@Injectable()
export class MedicalService {
  constructor(
    @InjectModel(Player.name)
    private readonly playerModel: Model<Player>,
    @InjectModel(MedicalRecord.name)
    private readonly medicalRecordModel: Model<MedicalRecord>,
    private readonly configService: ConfigService
  ) {
    this.pythonPath = this.configService.get<string>("MEDICAL_AI_PYTHON", "");
    this.scriptPath = this.configService.get<string>("MEDICAL_AI_SCRIPT", "");
  }

  private readonly pythonPath: string;
  private readonly scriptPath: string;

  // ===============================
  // Public method used by controller
  // ===============================
  async analyzePlayer(
    playerId: string,
    sessionData: { fatigue: number; minutes: number; load: number }
  ): Promise<MedicalAiResult> {
    const player = await this.playerModel.findById(playerId);

    if (!player) {
      throw new NotFoundException("Player not found");
    }

    const input = {
      age: player.age,
      fitness: player.baseFitness,
      history: player.injuryHistory,
      fatigue: sessionData.fatigue,
      minutes: sessionData.minutes,
      load: sessionData.load,
      forceInjured: player.isInjured === true,
      injuryTypeOverride: player.lastInjuryType ?? null,
    };

    console.log("🔥 Running Medical AI for player:", playerId);
    console.log("📤 AI input:", input);

    const result = await this.runMedicalAi(input);

    console.log("📥 AI result:", result);

    const keepInjury = player.isInjured === true && !result.injured;
    if (keepInjury) {
      const latestRecord = await this.medicalRecordModel
        .findOne({ playerId: new Types.ObjectId(playerId) })
        .sort({ createdAt: -1 })
        .lean();

      result.injured = true;
      result.injuryType =
        latestRecord?.injuryType ??
        player.lastInjuryType ??
        result.injuryType ??
        "Unknown";
      result.recoveryDays =
        latestRecord?.recoveryDays ??
        player.lastRecoveryDays ??
        result.recoveryDays ??
        0;
      result.severity =
        latestRecord?.severity ??
        player.lastSeverity ??
        result.severity ??
        "Mild";
      result.injuryProbability =
        latestRecord?.injuryProbability ??
        player.lastInjuryProbability ??
        result.injuryProbability;
      result.rehab =
        latestRecord?.rehab ?? result.rehab ?? [];
      result.prevention =
        latestRecord?.prevention ?? result.prevention ?? [];
      result.warning = result.warning || "Player is currently injured.";
    }
    this.normalizeInjuredResult(result);
    const updatePayload: Record<string, any> = {
      $set: {
        isInjured: keepInjury ? true : result.injured,
        lastInjuryType: keepInjury
          ? player.lastInjuryType ?? "Unknown"
          : result.injuryType ?? "Unknown",
        lastRecoveryDays: keepInjury
          ? player.lastRecoveryDays ?? 0
          : result.recoveryDays ?? 0,
        lastSeverity: keepInjury
          ? player.lastSeverity ?? "Mild"
          : result.severity ?? "Mild",
        lastInjuryProbability: keepInjury
          ? player.lastInjuryProbability ?? result.injuryProbability
          : result.injuryProbability,
      },
    };

    if (result.injured) {
      updatePayload.$inc = { injuryHistory: 1 };
      console.log("⚠ Injury history incremented for:", playerId);
    }

    await this.playerModel.findByIdAndUpdate(playerId, updatePayload);

    try {
      await this.medicalRecordModel.create({
        playerId: new Types.ObjectId(playerId),
        injuryProbability: result.injuryProbability,
        injured: keepInjury ? true : result.injured,
        injuryType: keepInjury
          ? player.lastInjuryType ?? "Unknown"
          : result.injuryType ?? "Unknown",
        recoveryDays: keepInjury
          ? player.lastRecoveryDays ?? 0
          : result.recoveryDays ?? 0,
        severity: keepInjury
          ? player.lastSeverity ?? "Mild"
          : result.severity ?? "Mild",
        rehab: result.rehab ?? [],
        prevention: result.prevention ?? [],
        warning: result.warning ?? "",
      });
    } catch (error) {
      console.error("Failed to store medical record:", error);
    }

    return result;
  }

  async analyzePlayersBatch(
    sessions: Array<{
      playerId: string;
      fatigue: number;
      minutes: number;
      load: number;
    }>
  ): Promise<Map<string, MedicalAiResult>> {
    if (sessions.length == 0) {
      return new Map();
    }

    const ids = sessions.map((item) => item.playerId);
    const players = await this.playerModel
      .find({ _id: { $in: ids } })
      .lean()
      .exec();

    const playerById = new Map(
      players.map((player) => [player._id.toString(), player])
    );

    const inputs = sessions
      .map((session) => {
        const player = playerById.get(session.playerId);
        if (!player) {
          return null;
        }
        return {
          playerId: session.playerId,
          age: player.age,
          fitness: player.baseFitness,
          history: player.injuryHistory,
          fatigue: session.fatigue,
          minutes: session.minutes,
          load: session.load,
          forceInjured: player.isInjured === true,
          injuryTypeOverride: player.lastInjuryType ?? null,
        };
      })
      .filter((item) => item !== null) as Array<Record<string, any>>;

    if (inputs.length == 0) {
      return new Map();
    }

    const results = await this.runMedicalAiBatch(inputs);
    if (!Array.isArray(results) || results.length != inputs.length) {
      throw new InternalServerErrorException("Invalid batch AI response");
    }

    const keepInjuryIds = Array.from(playerById.values())
      .filter((player) => player.isInjured === true)
      .map((player) => player._id.toString());
    const latestRecords = await this.getLatestMedicalRecords(keepInjuryIds);

    const resultMap = new Map<string, MedicalAiResult>();

    for (let i = 0; i < inputs.length; i += 1) {
      const input = inputs[i];
      const result = results[i];
      const playerId = result.playerId || input.playerId;
      if (!playerId) {
        continue;
      }

      const player = playerById.get(playerId);
      const keepInjury = player?.isInjured === true && !result.injured;
      if (keepInjury) {
        const latestRecord = latestRecords.get(playerId);
        result.injured = true;
        result.injuryType =
          latestRecord?.injuryType ??
          player?.lastInjuryType ??
          result.injuryType ??
          "Unknown";
        result.recoveryDays =
          latestRecord?.recoveryDays ??
          player?.lastRecoveryDays ??
          result.recoveryDays ??
          0;
        result.severity =
          latestRecord?.severity ??
          player?.lastSeverity ??
          result.severity ??
          "Mild";
        result.injuryProbability =
          latestRecord?.injuryProbability ??
          player?.lastInjuryProbability ??
          result.injuryProbability;
        result.rehab =
          latestRecord?.rehab ?? result.rehab ?? [];
        result.prevention =
          latestRecord?.prevention ?? result.prevention ?? [];
        result.warning = result.warning || "Player is currently injured.";
      }
      this.normalizeInjuredResult(result);
      const updatePayload: Record<string, any> = {
        $set: {
          isInjured: keepInjury ? true : result.injured,
          lastInjuryType: keepInjury
            ? player?.lastInjuryType ?? "Unknown"
            : result.injuryType ?? "Unknown",
          lastRecoveryDays: keepInjury
            ? player?.lastRecoveryDays ?? 0
            : result.recoveryDays ?? 0,
          lastSeverity: keepInjury
            ? player?.lastSeverity ?? "Mild"
            : result.severity ?? "Mild",
          lastInjuryProbability: keepInjury
            ? player?.lastInjuryProbability ?? result.injuryProbability
            : result.injuryProbability,
        },
      };

      if (result.injured) {
        updatePayload.$inc = { injuryHistory: 1 };
      }

      await this.playerModel.findByIdAndUpdate(playerId, updatePayload);

      try {
        await this.medicalRecordModel.create({
          playerId: new Types.ObjectId(playerId),
          injuryProbability: result.injuryProbability,
          injured: keepInjury ? true : result.injured,
          injuryType: keepInjury
            ? player?.lastInjuryType ?? "Unknown"
            : result.injuryType ?? "Unknown",
          recoveryDays: keepInjury
            ? player?.lastRecoveryDays ?? 0
            : result.recoveryDays ?? 0,
          severity: keepInjury
            ? player?.lastSeverity ?? "Mild"
            : result.severity ?? "Mild",
          rehab: result.rehab ?? [],
          prevention: result.prevention ?? [],
          warning: result.warning ?? "",
        });
      } catch (error) {
        console.error("Failed to store medical record:", error);
      }

      resultMap.set(playerId, result);
    }

    return resultMap;
  }

  async getHistory(playerId: string) {
    return this.medicalRecordModel
      .find({ playerId: new Types.ObjectId(playerId) })
      .sort({ createdAt: -1 })
      .limit(5)
      .lean();
  }

  // ===============================
  // Python execution logic
  // ===============================
  private runMedicalAi(input: any): Promise<MedicalAiResult> {
    return new Promise((resolve, reject) => {
      if (!this.pythonPath || !this.scriptPath) {
        return reject(
          new InternalServerErrorException(
            "Medical AI not configured. Set MEDICAL_AI_PYTHON and MEDICAL_AI_SCRIPT."
          )
        );
      }

      const payload = JSON.stringify(input);

      const process = spawn(this.pythonPath, [this.scriptPath, payload], {
        cwd: dirname(this.scriptPath),
      });

      let stdout = "";
      let stderr = "";

      process.stdout.on("data", (data) => {
        stdout += data.toString();
      });

      process.stderr.on("data", (data) => {
        stderr += data.toString();
      });

      process.on("close", (code) => {
        if (code !== 0) {
          return reject(
            new InternalServerErrorException(
              `Python error: ${stderr || "Unknown error"}`
            )
          );
        }

        try {
          const result = JSON.parse(stdout.trim());
          resolve(result);
        } catch (error) {
          reject(
            new InternalServerErrorException(
              `Invalid JSON from Python: ${stdout}`
            )
          );
        }
      });

      process.on("error", (err) => {
        reject(
          new InternalServerErrorException(
            `Failed to start Python: ${err.message}`
          )
        );
      });
    });
  }

  private runMedicalAiBatch(input: any[]): Promise<MedicalAiResult[]> {
    return new Promise((resolve, reject) => {
      if (!this.pythonPath || !this.scriptPath) {
        return reject(
          new InternalServerErrorException(
            "Medical AI not configured. Set MEDICAL_AI_PYTHON and MEDICAL_AI_SCRIPT."
          )
        );
      }

      const payload = JSON.stringify(input);

      const process = spawn(this.pythonPath, [this.scriptPath, payload], {
        cwd: dirname(this.scriptPath),
      });

      let stdout = "";
      let stderr = "";

      process.stdout.on("data", (data) => {
        stdout += data.toString();
      });

      process.stderr.on("data", (data) => {
        stderr += data.toString();
      });

      process.on("close", (code) => {
        if (code !== 0) {
          return reject(
            new InternalServerErrorException(
              `Python error: ${stderr || "Unknown error"}`
            )
          );
        }

        try {
          const result = JSON.parse(stdout.trim());
          if (!Array.isArray(result)) {
            return reject(
              new InternalServerErrorException(
                `Invalid JSON from Python: ${stdout}`
              )
            );
          }
          resolve(result);
        } catch (error) {
          reject(
            new InternalServerErrorException(
              `Invalid JSON from Python: ${stdout}`
            )
          );
        }
      });

      process.on("error", (err) => {
        reject(
          new InternalServerErrorException(
            `Failed to start Python: ${err.message}`
          )
        );
      });
    });
  }

  private normalizeInjuredResult(result: MedicalAiResult) {
    if (!result.injured) {
      return;
    }

    if (!result.injuryType || result.injuryType.trim() == "") {
      result.injuryType = "Unknown";
    }

    if (!result.recoveryDays || result.recoveryDays <= 0) {
      result.recoveryDays = 10;
    }

    if (!result.rehab || result.rehab.length == 0) {
      result.rehab = [
        "Rest and active recovery",
        "Physio-guided mobility work",
        "Gradual return to training",
      ];
    }

    if (!result.prevention || result.prevention.length == 0) {
      result.prevention = [
        "Monitor load and sleep",
        "Daily mobility routine",
        "Progressive return with low impact",
      ];
    }
  }

  private async getLatestMedicalRecords(playerIds: string[]) {
    if (playerIds.length == 0) {
      return new Map<string, MedicalRecord>();
    }

    const records = await this.medicalRecordModel
      .aggregate([
        { $match: { playerId: { $in: playerIds.map((id) => new Types.ObjectId(id)) } } },
        { $sort: { createdAt: -1 } },
        {
          $group: {
            _id: "$playerId",
            record: { $first: "$$ROOT" },
          },
        },
      ])
      .exec();

    const map = new Map<string, MedicalRecord>();
    for (const entry of records) {
      if (entry?._id && entry.record) {
        map.set(entry._id.toString(), entry.record as MedicalRecord);
      }
    }
    return map;
  }
}
