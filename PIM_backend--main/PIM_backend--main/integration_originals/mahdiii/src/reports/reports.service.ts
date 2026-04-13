import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import { MatchPlayer, MatchPlayerDocument } from "../matches/schemas/match-player.schema";
import { DEFAULT_PROVIDER } from "../common/constants";
import { AiService } from "../ai/ai.service";

@Injectable()
export class ReportsService {
  constructor(
    @InjectModel(MatchPlayer.name)
    private readonly matchPlayerModel: Model<MatchPlayerDocument>,
    private readonly aiService: AiService,
  ) {}

  async getMatchPlayerReport(
    providerMatchId: string,
    providerPlayerId: string,
    provider?: string,
  ) {
    const providerName = provider || DEFAULT_PROVIDER;
    const weights = this.aiService.getWeights();

    const pipeline = [
      {
        $match: {
          providerName,
          providerMatchId,
          providerPlayerId,
        },
      },
      {
        $lookup: {
          from: "matches",
          let: { providerName: "$providerName", providerMatchId: "$providerMatchId" },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$providerName", "$$providerName"] },
                    { $eq: ["$providerMatchId", "$$providerMatchId"] },
                  ],
                },
              },
            },
            {
              $project: {
                _id: 0,
                providerName: 1,
                providerMatchId: 1,
                date: 1,
                competitionName: 1,
                season: 1,
                homeTeam: 1,
                awayTeam: 1,
                homeScore: 1,
                awayScore: 1,
              },
            },
          ],
          as: "match",
        },
      },
      { $unwind: "$match" },
      {
        $lookup: {
          from: "players",
          let: { providerName: "$providerName", providerPlayerId: "$providerPlayerId" },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$providerName", "$$providerName"] },
                    { $eq: ["$providerPlayerId", "$$providerPlayerId"] },
                  ],
                },
              },
            },
            {
              $project: {
                _id: 0,
                name: 1,
                age: 1,
                position: 1,
                dateOfBirth: 1,
              },
            },
          ],
          as: "player",
        },
      },
      { $unwind: "$player" },
      {
        $lookup: {
          from: "medical_records",
          let: { providerName: "$providerName", providerPlayerId: "$providerPlayerId" },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$providerName", "$$providerName"] },
                    { $eq: ["$providerPlayerId", "$$providerPlayerId"] },
                  ],
                },
              },
            },
            {
              $project: {
                _id: 0,
                injuries: 1,
                recoveryEstimateDays: 1,
                lastUpdated: 1,
              },
            },
          ],
          as: "medical",
        },
      },
      { $unwind: { path: "$medical", preserveNullAndEmptyArrays: true } },
      {
        $lookup: {
          from: "fitness_snapshots",
          let: { providerName: "$providerName", providerPlayerId: "$providerPlayerId" },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$providerName", "$$providerName"] },
                    { $eq: ["$providerPlayerId", "$$providerPlayerId"] },
                  ],
                },
              },
            },
            {
              $project: {
                _id: 0,
                acuteLoad: 1,
                chronicLoad: 1,
                loadRatio: 1,
                fitnessScore: 1,
                fatigueScore: 1,
                lastUpdated: 1,
              },
            },
          ],
          as: "fitness",
        },
      },
      { $unwind: { path: "$fitness", preserveNullAndEmptyArrays: true } },
      {
        $addFields: {
          ai: {
            performanceScore: {
              $round: [
                {
                  $min: [
                    100,
                    {
                      $add: [
                        { $multiply: ["$rating", weights.performance.rating * 10] },
                        { $multiply: ["$goals", weights.performance.goals] },
                        { $multiply: ["$assists", weights.performance.assists] },
                        { $multiply: ["$tackles", weights.performance.tackles] },
                        { $multiply: ["$passes", weights.performance.passes] },
                        { $multiply: ["$yellowCards", weights.performance.yellowCard] },
                        { $multiply: ["$redCards", weights.performance.redCard] },
                      ],
                    },
                  ],
                },
                0,
              ],
            },
            prospectScore: {
              $round: [
                {
                  $min: [
                    100,
                    {
                      $max: [
                        0,
                        {
                          $add: [
                            {
                              $multiply: [
                                {
                                  $cond: [
                                    { $lte: ["$player.age", weights.prospect.ageMax] },
                                    { $subtract: [weights.prospect.ageMax, "$player.age"] },
                                    0,
                                  ],
                                },
                                3,
                              ],
                            },
                            { $multiply: ["$minutes", weights.prospect.minutes] },
                            { $multiply: ["$rating", weights.prospect.rating] },
                          ],
                        },
                      ],
                    },
                  ],
                },
                0,
              ],
            },
            injuryRiskScore: {
              $round: [
                {
                  $min: [
                    100,
                    {
                      $add: [
                        {
                          $multiply: [
                            {
                              $size: {
                                $filter: {
                                  input: { $ifNull: ["$medical.injuries", []] },
                                  as: "inj",
                                  cond: { $eq: ["$$inj.status", "active"] },
                                },
                              },
                            },
                            weights.injuryRisk.activeInjury,
                          ],
                        },
                        {
                          $multiply: [
                            {
                              $size: {
                                $filter: {
                                  input: { $ifNull: ["$medical.injuries", []] },
                                  as: "inj",
                                  cond: { $eq: ["$$inj.severity", "high"] },
                                },
                              },
                            },
                            weights.injuryRisk.highSeverity,
                          ],
                        },
                        {
                          $multiply: [
                            { $ifNull: ["$medical.recoveryEstimateDays", 0] },
                            weights.injuryRisk.recoveryDays,
                          ],
                        },
                        {
                          $multiply: [
                            { $ifNull: ["$fitness.loadRatio", 0] },
                            weights.injuryRisk.workloadRatio,
                          ],
                        },
                        {
                          $multiply: [
                            { $ifNull: ["$fitness.fatigueScore", 0] },
                            weights.injuryRisk.fatigue,
                          ],
                        },
                      ],
                    },
                  ],
                },
                0,
              ],
            },
          },
        },
      },
      {
        $addFields: {
          "ai.topFactors": {
            $concatArrays: [
              {
                $cond: [
                  { $gte: ["$rating", 7.5] },
                  ["High match rating"],
                  [],
                ],
              },
              {
                $cond: [
                  { $gte: ["$goals", 1] },
                  ["Goal contribution"],
                  [],
                ],
              },
              {
                $cond: [
                  { $gte: ["$assists", 1] },
                  ["Assist contribution"],
                  [],
                ],
              },
              {
                $cond: [
                  { $gte: ["$fitness.loadRatio", 1.3] },
                  ["High workload ratio"],
                  [],
                ],
              },
              {
                $cond: [
                  { $gt: [{ $ifNull: ["$medical.recoveryEstimateDays", 0] }, 0] },
                  ["Active recovery window"],
                  [],
                ],
              },
            ],
          },
          "ai.recommendations": {
            $concatArrays: [
              {
                $cond: [
                  { $lt: ["$ai.performanceScore", 50] },
                  ["Increase technical and tactical focus"],
                  [],
                ],
              },
              {
                $cond: [
                  { $gt: ["$ai.injuryRiskScore", 70] },
                  ["Reduce workload and enhance recovery"],
                  [],
                ],
              },
              {
                $cond: [
                  { $gte: ["$ai.prospectScore", 70] },
                  ["Prioritize development minutes"],
                  [],
                ],
              },
            ],
          },
        },
      },
      {
        $project: {
          _id: 0,
          match: 1,
          player: 1,
          lineup: {
            status: "$lineupStatus",
            minutes: "$minutes",
            position: "$position",
            team: "$teamName",
          },
          statistics: {
            rating: "$rating",
            goals: "$goals",
            assists: "$assists",
            shots: "$shots",
            passes: "$passes",
            tackles: "$tackles",
            yellowCards: "$yellowCards",
            redCards: "$redCards",
          },
          medical: 1,
          fitness: 1,
          ai: 1,
        },
      },
    ];

    const [report] = await this.matchPlayerModel.aggregate(pipeline).exec();
    return report || null;
  }
}
