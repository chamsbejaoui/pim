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
  risk?: number;
  confidence?: number;
  status?: "SAFE" | "WARNING" | "INJURED";
  decision?: "PLAY" | "LIMIT" | "SUBSTITUTE";
  reason?: string[];
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

    const input = this.buildAiInput(player, sessionData);

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
        "Muscle fatigue";
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
          ? player.lastInjuryType ?? "Muscle fatigue"
          : result.injuryType ?? "Muscle fatigue",
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
          ? player.lastInjuryType ?? "Muscle fatigue"
          : result.injuryType ?? "Muscle fatigue",
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

    const risk = result.injuryProbability ?? 0;
    const { status, decision } = this.classifyRisk(risk);
    const reason = this.buildReasonList(sessionData, result.warning);
    const confidence = this.computeConfidence(sessionData, risk);

    return {
      ...result,
      risk,
      confidence,
      status,
      decision,
      reason,
    };
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
        return this.buildAiInput(player, session);
      })
      .filter((item) => item !== null) as Array<Record<string, any>>;

    if (inputs.length == 0) {
      return new Map();
    }

    const results = await this.runMedicalAiBatch(inputs);
    if (!Array.isArray(results) || results.length != inputs.length) {
      throw new InternalServerErrorException("Invalid batch AI response");
    }

    this.capBatchInjuries(results, 2);

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
          "Muscle fatigue";
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
      result.confidence = this.computeConfidence(
        {
          fatigue: input.fatigue,
          minutes: input.minutes,
          load: input.load,
        },
        result.injuryProbability ?? 0,
      );
      const updatePayload: Record<string, any> = {
        $set: {
          isInjured: keepInjury ? true : result.injured,
          lastInjuryType: keepInjury
            ? player?.lastInjuryType ?? "Muscle fatigue"
            : result.injuryType ?? "Muscle fatigue",
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
            ? player?.lastInjuryType ?? "Muscle fatigue"
            : result.injuryType ?? "Muscle fatigue",
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
      result.injuryType = "Muscle fatigue";
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

  private classifyRisk(risk: number) {
    if (risk < 0.25) {
      return { status: "SAFE" as const, decision: "PLAY" as const };
    }
    if (risk <= 0.4) {
      return { status: "WARNING" as const, decision: "LIMIT" as const };
    }
    return { status: "INJURED" as const, decision: "SUBSTITUTE" as const };
  }

  private buildReasonList(
    sessionData: { fatigue: number; minutes: number; load: number },
    warning?: string
  ) {
    const reasons: string[] = [];
    if (sessionData.fatigue >= 70) {
      reasons.push("High fatigue");
    }
    if (sessionData.load >= 70) {
      reasons.push("High load");
    }
    if (sessionData.minutes >= 75) {
      reasons.push("High minutes");
    }
    if (reasons.length === 0 && warning && warning.trim().length > 0) {
      reasons.push(warning.trim());
    }
    if (reasons.length === 0) {
      reasons.push("Elevated injury risk");
    }
    return reasons;
  }

  private computeConfidence(
    sessionData: { fatigue: number; minutes: number; load: number },
    risk: number
  ) {
    const fatigue = this.coerceNumber(sessionData.fatigue, 0);
    const minutes = this.coerceNumber(sessionData.minutes, 0);
    const load = this.coerceNumber(sessionData.load, 0);
    const stress = (fatigue + load + Math.min(minutes, 90)) / 260;
    const raw = 0.9 - risk * 0.25 - stress * 0.1;
    const clamped = Math.max(0.6, Math.min(0.95, raw));
    return Math.round(clamped * 100) / 100;
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

  private capBatchInjuries(results: MedicalAiResult[], maxInjuries: number) {
    if (!Array.isArray(results) || results.length == 0) {
      return;
    }
    const injured = results
      .map((result, index) => ({ index, result }))
      .filter(({ result }) => result.injured === true);

    if (injured.length <= maxInjuries) {
      return;
    }

    injured.sort(
      (a, b) => b.result.injuryProbability - a.result.injuryProbability,
    );

    const allowed = new Set(
      injured.slice(0, maxInjuries).map((entry) => entry.index),
    );

    for (const { index } of injured.slice(maxInjuries)) {
      const current = results[index];
      results[index] = {
        ...current,
        injured: false,
        injuryType: null,
        recoveryDays: 0,
        severity: "Mild",
        rehab: [],
        prevention: [],
        warning: "",
      };
    }
  }

  private buildAiInput(
    player: Player,
    session: { fatigue: number; minutes: number; load: number; playerId?: string }
  ) {
    return {
      playerId: session.playerId,
      age: this.resolveAge(player),
      fitness: this.coerceNumber(player.baseFitness, 75),
      history: this.coerceNumber(player.injuryHistory, 0),
      fatigue: this.coerceNumber(session.fatigue, 0),
      minutes: this.coerceNumber(session.minutes, 0),
      load: this.coerceNumber(session.load, 0),
      forceInjured: player.isInjured === true,
      injuryTypeOverride: player.lastInjuryType ?? null,
    };
  }

  private resolveAge(player: Player): number {
    const age = this.coerceNumber(player.age, NaN);
    if (Number.isFinite(age) && age > 0) {
      return Math.round(age);
    }

    const dob = player.dateOfBirth ? new Date(player.dateOfBirth) : null;
    if (dob && !Number.isNaN(dob.getTime())) {
      const now = new Date();
      let years = now.getFullYear() - dob.getFullYear();
      const m = now.getMonth() - dob.getMonth();
      if (m < 0 || (m == 0 && now.getDate() < dob.getDate())) {
        years -= 1;
      }
      if (years > 0) {
        return years;
      }
    }

    return 24;
  }

  private coerceNumber(value: any, fallback: number): number {
    if (typeof value === "number" && Number.isFinite(value)) {
      return value;
    }
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
    return fallback;
  }
}
