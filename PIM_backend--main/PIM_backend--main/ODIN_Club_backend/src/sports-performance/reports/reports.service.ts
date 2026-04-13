import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Event, EventDocument, EventStatus } from '../events/entities/event.entity';
import { EventPlayer, EventPlayerDocument } from '../event-players/entities/event-player.entity';
import { TestResult, TestResultDocument } from '../test-results/entities/test-result.entity';
import { TestType, TestTypeDocument } from '../test-types/entities/test-type.entity';
import { Player, PlayerDocument } from '../players/entities/player.entity';
import { EventReport, EventReportDocument } from './entities/event-report.entity';
import { PlayerReport, PlayerReportDocument } from './entities/player-report.entity';
import { ScoringService } from '../scoring/scoring.service';

@Injectable()
export class ReportsService {
    constructor(
        @InjectModel(Event.name) private eventModel: Model<EventDocument>,
        @InjectModel(EventPlayer.name) private eventPlayerModel: Model<EventPlayerDocument>,
        @InjectModel(TestResult.name) private testResultModel: Model<TestResultDocument>,
        @InjectModel(TestType.name) private testTypeModel: Model<TestTypeDocument>,
        @InjectModel(Player.name) private playerModel: Model<PlayerDocument>,
        @InjectModel(EventReport.name) private eventReportModel: Model<EventReportDocument>,
        @InjectModel(PlayerReport.name) private playerReportModel: Model<PlayerReportDocument>,
        private scoringService: ScoringService,
    ) { }

    /**
     * Génère tous les rapports pour un événement (global + individuels)
     */
    async generateAllReports(eventId: string): Promise<any> {
        // Validation check for eventId
        if (!eventId || !Types.ObjectId.isValid(eventId)) {
            throw new BadRequestException(`Invalid Event ID: ${eventId}`);
        }

        // Vérifier que l'événement existe et est terminé
        const event = await this.eventModel.findById(eventId).exec();
        if (!event) {
            throw new NotFoundException(`Event with ID ${eventId} not found`);
        }

        if (event.status !== EventStatus.COMPLETED) {
            throw new BadRequestException('Event must be completed before generating reports');
        }

        // Récupérer tous les joueurs de l'événement
        let eventPlayers = await this.eventPlayerModel
            .find({ eventId: new Types.ObjectId(eventId) })
            .populate({
                path: 'playerId',
                match: { _id: { $ne: null } }
            })
            .exec();

        // Safety check: Filter out players that might have been deleted or have invalid IDs
        eventPlayers = eventPlayers.filter(ep => ep.playerId != null);

        if (eventPlayers.length === 0) {
            throw new BadRequestException('No valid players found for this event');
        }

        // Calculer les scores pour chaque joueur
        const playerScores: Array<{ eventPlayerId: Types.ObjectId; playerId: Types.ObjectId; score: number; testScores: any[] }> = [];

        for (const eventPlayer of eventPlayers) {
            // Récupérer tous les résultats de tests pour ce joueur
            const testResults = await this.testResultModel
                .find({ eventPlayerId: eventPlayer._id })
                .populate('testTypeId')
                .exec();

            if (testResults.length > 0) {
                // Calculer le score global
                const testScoresData = testResults
                    .filter(result => result.testTypeId != null)
                    .map(result => ({
                        score: result.normalizedScore,
                        testTypeId: result.testTypeId._id.toString(),
                    }));

                const overallScore = await this.scoringService.calculatePlayerOverallScore(testScoresData);

                // Préparer les scores détaillés par test
                const detailedTestScores = testResults
                    .filter(result => result.testTypeId != null)
                    .map(result => {
                        const testType = result.testTypeId as any;
                        return {
                            testTypeId: testType._id,
                            testName: testType.name,
                            score: result.normalizedScore,
                            category: testType.category,
                        };
                    });

                playerScores.push({
                    eventPlayerId: eventPlayer._id as Types.ObjectId,
                    playerId: eventPlayer.playerId._id as Types.ObjectId,
                    score: overallScore,
                    testScores: detailedTestScores,
                });
            }
        }

        // Calculer les statistiques de l'événement
        const scores = playerScores.map(p => p.score);
        const stats = this.scoringService.calculateEventStatistics(scores);

        // Classer les joueurs
        const rankedPlayers = this.scoringService.rankPlayers(
            playerScores.map(p => ({ playerId: p.playerId, score: p.score }))
        );

        // Identifier les top players
        const topPlayers = this.scoringService.identifyTopPlayers(
            playerScores.map(p => ({ playerId: p.playerId.toString(), score: p.score })),
            75 // Seuil 75/100
        );

        // Générer le rapport global
        const eventReport = await this.createEventReport(
            eventId,
            playerScores.length,
            playerScores.reduce((sum, p) => sum + p.testScores.length, 0),
            stats.averageScore,
            topPlayers.slice(0, 5), // Top 5
            rankedPlayers,
            stats,
            playerScores
        );

        // Générer les rapports individuels
        const playerReports: PlayerReport[] = [];
        for (const playerScore of playerScores) {
            const ranked = rankedPlayers.find(r => r.playerId.toString() === playerScore.playerId.toString());
            const isTopPlayer = topPlayers.some(t => t.playerId === playerScore.playerId.toString());

            const playerReport = await this.createPlayerReport(
                playerScore.eventPlayerId.toString(),
                playerScore.score,
                ranked!.rank,
                playerScores.length,
                stats.averageScore,
                playerScore.testScores,
                isTopPlayer
            );

            playerReports.push(playerReport);
        }

        return { eventReport, playerReports };
    }

    /**
     * Crée le rapport global de l'événement
     */
    private async createEventReport(
        eventId: string,
        totalPlayers: number,
        completedTests: number,
        averageScore: number,
        topPlayers: any[],
        ranking: any[],
        statistics: any,
        playerScores: any[]
    ): Promise<EventReport> {
        // Fetch all player reports to get scoreTrend data
        const playerReports = await this.playerReportModel
            .find({
                eventPlayerId: {
                    $in: playerScores.map(ps => new Types.ObjectId(ps.eventPlayerId))
                }
            })
            .exec();

        // Create a map for quick lookup
        const reportMap = new Map(
            playerReports.map(pr => [pr.eventPlayerId.toString(), pr])
        );

        // Supprimer l'ancien rapport s'il existe
        await this.eventReportModel.deleteOne({ eventId: new Types.ObjectId(eventId) }).exec();

        // Calculer les statistiques par catégorie
        const statsByCategory: Record<string, { avg: number; min: number; max: number }> = {};
        const categoryData: Record<string, number[]> = {};

        for (const ps of playerScores) {
            for (const ts of ps.testScores) {
                const cat = ts.category;
                if (!categoryData[cat]) categoryData[cat] = [];
                categoryData[cat].push(ts.score);
            }
        }

        for (const [category, scores] of Object.entries(categoryData)) {
            if (scores.length > 0) {
                statsByCategory[category] = {
                    avg: scores.reduce((a, b) => a + b, 0) / scores.length,
                    min: Math.min(...scores),
                    max: Math.max(...scores),
                };
            }
        }

        const eventReport = new this.eventReportModel({
            eventId: new Types.ObjectId(eventId),
            totalPlayers,
            completedTests,
            averageScore,
            topPlayers: topPlayers.map(p => {
                const pScore = playerScores.find(ps => ps.playerId.toString() === p.playerId.toString());
                const report = pScore ? reportMap.get(pScore.eventPlayerId.toString()) : null;
                return {
                    playerId: new Types.ObjectId(p.playerId),
                    eventPlayerId: pScore?.eventPlayerId,
                    score: p.score,
                    rank: ranking.find(r => r.playerId.toString() === p.playerId)?.rank || 0,
                    scoreTrend: report?.scoreTrend || 0,
                };
            }),
            ranking: ranking.map(r => {
                const pScore = playerScores.find(ps => ps.playerId.toString() === r.playerId.toString());
                const report = pScore ? reportMap.get(pScore.eventPlayerId.toString()) : null;
                return {
                    playerId: r.playerId,
                    eventPlayerId: pScore?.eventPlayerId,
                    score: r.score,
                    rank: r.rank,
                    scoreTrend: report?.scoreTrend || 0,
                };
            }),
            statistics: {
                byCategory: statsByCategory,
                distribution: statistics,
            },
        });

        return eventReport.save();
    }

    /**
     * Crée le rapport individuel d'un joueur
     */
    private async createPlayerReport(
        eventPlayerId: string,
        overallScore: number,
        rank: number,
        totalPlayers: number,
        eventAverage: number,
        testScores: any[],
        isTopPlayer: boolean
    ): Promise<PlayerReport> {
        // Fetch previous report for trend analysis
        const eventPlayer = await this.eventPlayerModel.findById(eventPlayerId).populate('playerId').exec();
        let scoreTrend = 0;

        if (eventPlayer) {
            // Find the most recent completed event for this player (excluding current event)
            const previousEventPlayer = await this.eventPlayerModel
                .findOne({
                    playerId: eventPlayer.playerId,
                    _id: { $ne: new Types.ObjectId(eventPlayerId) },
                })
                .sort({ createdAt: -1 })
                .exec();

            if (previousEventPlayer) {
                // Fetch the previous player report
                const previousReport = await this.playerReportModel
                    .findOne({ eventPlayerId: previousEventPlayer._id })
                    .exec();

                if (previousReport) {
                    scoreTrend = overallScore - previousReport.overallScore;
                }
            }
        }

        // Supprimer l'ancien rapport s'il existe
        await this.playerReportModel.deleteOne({ eventPlayerId: new Types.ObjectId(eventPlayerId) }).exec();

        // Calculer la déviation
        const comparison = this.scoringService.compareToAverage(overallScore, eventAverage);

        // Identifier forces et faiblesses
        const { strengths, weaknesses } = this.scoringService.identifyStrengthsAndWeaknesses(testScores);

        // Générer recommandation
        let recommendation = '';
        if (comparison.performance === 'excellent') {
            recommendation = 'Excellent performance ! Joueur à fort potentiel pour la sélection.';
        } else if (comparison.performance === 'above_average') {
            recommendation = 'Bonne performance globale. Continuer le développement sur les points faibles.';
        } else if (comparison.performance === 'average') {
            recommendation = 'Performance moyenne. Nécessite un travail ciblé pour progresser.';
        } else {
            recommendation = 'Performance en dessous de la moyenne. Programme de renforcement recommandé.';
        }

        const playerReport = new this.playerReportModel({
            eventPlayerId: new Types.ObjectId(eventPlayerId),
            overallScore,
            rank,
            totalPlayers,
            eventAverage,
            deviation: comparison.deviation,
            scoreTrend,
            testScores,
            strengths,
            weaknesses,
            recommendation,
            isTopPlayer,
        });

        return playerReport.save();
    }

    /**
     * Récupère le rapport global d'un événement
     */
    async getEventReport(eventId: string): Promise<EventReport> {
        if (!Types.ObjectId.isValid(eventId)) {
            throw new NotFoundException(`Report not found for event ${eventId}.`);
        }

        const report = await this.eventReportModel
            .findOne({ eventId: new Types.ObjectId(eventId) })
            .exec();

        if (!report) {
            throw new NotFoundException(`Report not found for event ${eventId}. Generate reports first.`);
        }

        // Safe population for ranking and topPlayers
        for (const playerEntry of report.ranking) {
            if (playerEntry.playerId && Types.ObjectId.isValid(playerEntry.playerId.toString())) {
                try {
                    await (report as any).populate('ranking.playerId');
                    break; // Populate all in the array with one call
                } catch (e) { }
            }
        }

        for (const playerEntry of report.topPlayers) {
            if (playerEntry.playerId && Types.ObjectId.isValid(playerEntry.playerId.toString())) {
                try {
                    await (report as any).populate('topPlayers.playerId');
                    break;
                } catch (e) { }
            }
        }

        return report;
    }

    /**
     * Récupère le rapport individuel d'un joueur
     */
    async getPlayerReport(eventPlayerId: string): Promise<PlayerReport> {
        if (!Types.ObjectId.isValid(eventPlayerId)) {
            throw new NotFoundException(`Report not found for event player ${eventPlayerId}.`);
        }

        const report = await this.playerReportModel
            .findOne({ eventPlayerId: new Types.ObjectId(eventPlayerId) })
            .exec();

        if (!report) {
            throw new NotFoundException(`Report not found for event player ${eventPlayerId}. Generate reports first.`);
        }

        // Safe manual population
        if (report.eventPlayerId && Types.ObjectId.isValid(report.eventPlayerId.toString())) {
            try {
                await report.populate({
                    path: 'eventPlayerId',
                    populate: { path: 'playerId' }
                });
            } catch (e) {
                console.error(`Failed to populate eventPlayerId for player report: ${e.message}`);
            }
        }

        return report;
    }

    /**
     * Récupère le classement complet d'un événement
     */
    async getEventRanking(eventId: string): Promise<EventReport> {
        return this.getEventReport(eventId);
    }

    /**
     * Récupère les top players d'un événement
     */
    async getTopPlayers(eventId: string): Promise<any[]> {
        const report = await this.getEventReport(eventId);
        return report.topPlayers;
    }
}
