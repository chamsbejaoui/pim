import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CognitiveSession, CognitiveSessionDocument } from '../entities/cognitive-session.entity';
import { CreateCognitiveSessionDto } from '../dto/create-cognitive-session.dto';
import { CognitiveAiService } from './cognitive-ai.service';
import { Player, PlayerDocument } from '../../../players/schemas/player.schema';

@Injectable()
export class CognitiveLabService {
    constructor(
        @InjectModel(CognitiveSession.name) private sessionModel: Model<CognitiveSessionDocument>,
        @InjectModel(Player.name) private playerModel: Model<PlayerDocument>,
        private aiService: CognitiveAiService
    ) { }

    async createSession(dto: CreateCognitiveSessionDto): Promise<CognitiveSession> {
        const scores = this.aiService.calculateScores(dto);

        // Calculate 7-day baseline for AI Comparison
        const baseline = await this.getBaseline(dto.playerId);

        const aiAssessment = this.aiService.generateAiAssessment(scores, baseline);

        const newSession = new this.sessionModel({
            playerId: new Types.ObjectId(dto.playerId),
            reaction: dto.reaction,
            focus: dto.focus,
            memory: dto.memory,
            decision: dto.decision,
            wellness: dto.wellness,
            scores: scores,
            ...aiAssessment
        });

        const savedSession = await newSession.save();

        // System Notification / Coach Alert Mock
        if (aiAssessment.riskLevel === 'CRITICAL' || aiAssessment.riskLevel === 'HIGH') {
            this.sendCoachAlert(dto.playerId, savedSession);
        }

        return savedSession;
    }

    private sendCoachAlert(playerId: string, session: CognitiveSession) {
        // Integration point for Firebase Admin / Push Notifications or Internal Entity
        console.warn(`[URGENT COACH ALERT] Player ${playerId} presents a ${session.riskLevel} injury risk. AI status: ${session.aiStatus}`);

        const pushPayload = {
            title: "Player Cognitive Alert",
            body: `Player ${playerId} has dropped to ${session.aiStatus}. ${session.trainingSuggestion}`,
            data: { risk: session.riskLevel, mentalScore: session.scores?.mentalScore }
        };

        console.log(`Push Notification Triggered: ${JSON.stringify(pushPayload)}`);
    }

    async getBaseline(playerId: string): Promise<any> {
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const sessions = await this.sessionModel.find({
            playerId: new Types.ObjectId(playerId),
            date: { $gte: sevenDaysAgo }
        }).exec();

        const validSessions = sessions.filter(s => s.scores && s.scores.mentalScore !== undefined);

        if (!validSessions || validSessions.length === 0) return null;

        const sumScore = validSessions.reduce((acc, curr) => acc + curr.scores.mentalScore!, 0);
        return { mentalScore: sumScore / validSessions.length };
    }

    async getPlayerDashboard(playerId: string) {
        const player = await this.playerModel.findById(playerId).exec();
        const recentSession = await this.sessionModel.findOne({ playerId: new Types.ObjectId(playerId) })
            .sort({ date: -1 })
            .exec();

        const baseline = await this.getBaseline(playerId);

        // Add history (last 14 days)
        const fourteenDaysAgo = new Date();
        fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14);

        const historyData = await this.sessionModel.find({
            playerId: new Types.ObjectId(playerId),
            date: { $gte: fourteenDaysAgo }
        })
            .sort({ date: 1 })
            .exec();

        const history = historyData.map(s => ({
            date: s.date,
            mentalScore: s.scores?.mentalScore
        })).filter(h => h.mentalScore !== undefined);

        return {
            latestSession: recentSession,
            baseline: baseline,
            history: history,
            playerInfo: player ? {
                firstName: player.firstName,
                lastName: player.lastName,
                position: player.position
            } : null
        };
    }

    async getSquadOverviewToday() {
        const startOfDay = new Date();
        startOfDay.setHours(0, 0, 0, 0);

        const sessionsToday = await this.sessionModel.find({
            date: { $gte: startOfDay }
        }).exec();

        // Filter out tactical-only sessions for cognitive overview
        const cognitiveSessions = sessionsToday.filter(s => s.scores && s.scores.mentalScore !== undefined);

        const latestSessions = new Map<string, CognitiveSession>();
        for (const session of cognitiveSessions) {
            const pid = session.playerId.toString();
            if (!latestSessions.has(pid) || session.date > latestSessions.get(pid)!.date) {
                latestSessions.set(pid, session);
            }
        }

        const playerIds = Array.from(latestSessions.keys()).map(id => new Types.ObjectId(id));
        const playersData = await this.playerModel.find({ _id: { $in: playerIds } }).exec();
        const playerMap = new Map(playersData.map(p => [p._id.toString(), p]));

        const summary = {
            READY: 0,
            NORMAL: 0,
            FATIGUED: 0,
            OVERLOADED: 0,
            CRITICAL: 0,
            'RECOVERY REQUIRED': 0
        };

        const atRiskPlayers: any[] = [];
        const allSessions: any[] = [];

        for (const session of latestSessions.values()) {
            const pid = session.playerId.toString();
            const player = playerMap.get(pid);
            const status = session.aiStatus;
            
            if (summary[status] !== undefined) summary[status]++;
            else summary[status] = 1;

            const sessionInfo = {
                playerId: pid,
                playerName: player ? `${player.firstName} ${player.lastName}` : 'Unknown Player',
                playerPosition: player?.position || 'N/A',
                status: session.aiStatus,
                riskLevel: session.riskLevel,
                mentalScore: session.scores.mentalScore,
                recommendation: session.aiRecommendationText,
                trainingSuggestion: session.trainingSuggestion,
                date: session.date
            };

            allSessions.push(sessionInfo);

            if (session.riskLevel === 'HIGH' || session.riskLevel === 'CRITICAL') {
                atRiskPlayers.push(sessionInfo);
            }
        }

        return {
            summary,
            allSessions: allSessions.sort((a, b) => b.mentalScore - a.mentalScore),
            atRiskPlayers: atRiskPlayers.sort((a, b) => a.mentalScore - b.mentalScore)
        };
    }
}
