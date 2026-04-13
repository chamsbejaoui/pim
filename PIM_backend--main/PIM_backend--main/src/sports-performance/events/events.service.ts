import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Event, EventDocument, EventStatus } from './entities/event.entity';
import { CreateEventDto } from './dto/create-event.dto';
import { UpdateEventDto } from './dto/update-event.dto';
import {
    EventPlayer,
    EventPlayerDocument,
    ParticipationStatus,
    AiAnalysisResult,
} from '../event-players/entities/event-player.entity';
import { TestResult, TestResultDocument } from '../test-results/entities/test-result.entity';
import { AiService } from '../../ai/ai.service';

@Injectable()
export class EventsService {
    constructor(
        @InjectModel(Event.name) private eventModel: Model<EventDocument>,
        @InjectModel(EventPlayer.name) private eventPlayerModel: Model<EventPlayerDocument>,
        @InjectModel(TestResult.name) private testResultModel: Model<TestResultDocument>,
        private readonly aiService: AiService,
    ) { }

    async create(createEventDto: CreateEventDto): Promise<Event> {
        const event = new this.eventModel({
            ...createEventDto,
            coachId: new Types.ObjectId(createEventDto.coachId),
            testTypes: createEventDto.testTypes?.map(id => new Types.ObjectId(id)) || [],
        });
        return event.save();
    }

    async findAll(filters?: {
        startDate?: Date;
        endDate?: Date;
        status?: EventStatus;
    }): Promise<Event[]> {
        const query: any = {};

        if (filters?.startDate || filters?.endDate) {
            query.date = {};
            if (filters.startDate) query.date.$gte = filters.startDate;
            if (filters.endDate) query.date.$lte = filters.endDate;
        }

        if (filters?.status) {
            query.status = filters.status;
        }

        const events = await this.eventModel
            .find(query)
            .populate('testTypes')
            .sort({ date: -1 })
            .exec();

        // Safe population for coachId
        for (const event of events) {
            if (event.coachId && Types.ObjectId.isValid(event.coachId.toString())) {
                try {
                    await event.populate('coachId', 'firstName lastName');
                } catch (e: any) {
                    console.error(`Failed to populate coachId for event ${event._id}: ${e?.message}`);
                }
            }
        }

        return events;
    }

    async findOne(id: string): Promise<Event> {
        // First check if id is a valid ObjectId
        if (!Types.ObjectId.isValid(id)) {
            throw new BadRequestException(`Invalid Event ID: ${id}`);
        }

        const event = await this.eventModel.findById(id).exec();

        if (!event) {
            throw new NotFoundException(`Event with ID ${id} not found`);
        }

        // Manually populate to ensure safety against invalid ref strings
        if (event.coachId && Types.ObjectId.isValid(event.coachId.toString())) {
            await event.populate('coachId', 'firstName lastName');
        }
        await event.populate('testTypes');

        return event;
    }

    async update(id: string, updateEventDto: UpdateEventDto): Promise<Event> {
        const updateData: any = { ...updateEventDto };

        if ('coachId' in updateEventDto && updateEventDto.coachId) {
            if (Types.ObjectId.isValid(updateEventDto.coachId as string)) {
                updateData.coachId = new Types.ObjectId(updateEventDto.coachId as string);
            } else {
                delete updateData.coachId;
            }
        }

        if ('testTypes' in updateEventDto && updateEventDto.testTypes) {
            updateData.testTypes = (updateEventDto.testTypes as string[]).map(id => new Types.ObjectId(id));
        }

        const event = await this.eventModel
            .findByIdAndUpdate(id, updateData, { new: true })
            .exec();

        if (!event) {
            throw new NotFoundException(`Event with ID ${id} not found`);
        }

        // Safe manual population
        if (event.coachId && Types.ObjectId.isValid(event.coachId.toString())) {
            await event.populate('coachId', 'firstName lastName');
        }
        await event.populate('testTypes');

        return event;
    }

    async remove(id: string): Promise<void> {
        const result = await this.eventModel.findByIdAndDelete(id).exec();
        if (!result) {
            throw new NotFoundException(`Event with ID ${id} not found`);
        }
    }

    async closeEvent(id: string): Promise<Event> {
        const event = await this.findOne(id);

        if (event.status === EventStatus.COMPLETED) {
            throw new BadRequestException('Event is already completed');
        }

        event.status = EventStatus.COMPLETED;
        const updated = await this.eventModel
            .findByIdAndUpdate(id, { status: EventStatus.COMPLETED }, { new: true })
            .exec();
        if (!updated) {
            throw new NotFoundException(`Event with ID ${id} not found`);
        }
        return updated;
    }

    /**
     * Analyse IA de tous les joueurs complétés dans un event.
     * - Récupère tous les EventPlayers avec status=COMPLETED
     * - Pour chaque joueur, récupère ses TestResults et calcule les métriques IA
     * - Appelle AiService.predict() et stocke le résultat dans eventPlayer.aiAnalysis
     * - Retourne un récapitulatif par joueur
     */
    async analyzeEventPlayers(eventId: string): Promise<{
        analyzed: number;
        failed: number;
        results: Array<{
            eventPlayerId: string;
            playerId: string;
            aiAnalysis: AiAnalysisResult | null;
            error?: string;
        }>;
    }> {
        if (!Types.ObjectId.isValid(eventId)) {
            throw new BadRequestException(`Invalid Event ID: ${eventId}`);
        }

        // Vérifier que l'event existe
        const event = await this.eventModel.findById(eventId).exec();
        if (!event) {
            throw new NotFoundException(`Event with ID ${eventId} not found`);
        }

        // Récupérer tous les EventPlayers complétés de cet event
        const eventPlayers = await this.eventPlayerModel
            .find({
                eventId: new Types.ObjectId(eventId),
                status: ParticipationStatus.COMPLETED,
            })
            .populate('playerId')
            .exec();

        if (eventPlayers.length === 0) {
            return { analyzed: 0, failed: 0, results: [] };
        }

        let analyzed = 0;
        let failed = 0;
        const results: Array<{
            eventPlayerId: string;
            playerId: string;
            aiAnalysis: AiAnalysisResult | null;
            error?: string;
        }> = [];

        for (const ep of eventPlayers) {
            const epId = (ep as any)._id.toString();
            let playerId = 'unknown';

            try {
                const populatedPlayer = ep.playerId as any;
                playerId =
                    populatedPlayer?._id?.toString?.() ??
                    populatedPlayer?.toString?.() ??
                    'unknown';

                if (playerId === 'unknown') {
                    failed++;
                    results.push({
                        eventPlayerId: epId,
                        playerId,
                        aiAnalysis: null,
                        error: 'EventPlayer has no linked player',
                    });
                    continue;
                }

                // Récupérer les résultats de tests de ce joueur
                const testResults = await this.testResultModel
                    .find({ eventPlayerId: ep._id })
                    .populate('testTypeId')
                    .exec();

                // Mapper les résultats vers les métriques IA
                const aiMetrics = this.mapTestResultsToAiMetrics(testResults, ep.playerId as any);

                // Appel au modèle IA
                const prediction = await this.aiService.predict(aiMetrics);
                const potential = await this.aiService.getPotential(aiMetrics).catch(() => null);

                const aiAnalysis: AiAnalysisResult = {
                    recruited: this.resolveRecruitmentDecision(prediction),
                    confidence: this.resolveConfidence01(prediction),
                    cluster:
                        prediction?.cluster_label ??
                        prediction?.cluster ??
                        prediction?.cluster_profile?.toString() ??
                        undefined,
                    potentialScore: potential?.potential_score ?? prediction?.potential_score ?? undefined,
                    shap: prediction?.shap_explanation ?? prediction?.shap ?? undefined,
                    analyzedAt: new Date(),
                    // ← Persist real test stats so Flutter can use them directly
                    metrics: {
                        speed: aiMetrics.speed,
                        endurance: aiMetrics.endurance,
                        distance: aiMetrics.distance,
                        dribbles: aiMetrics.dribbles,
                        shots: aiMetrics.shots,
                        injuries: aiMetrics.injuries,
                        heart_rate: aiMetrics.heart_rate,
                    },
                };

                // Stocker le résultat dans EventPlayer
                await this.eventPlayerModel.findByIdAndUpdate(
                    ep._id,
                    { aiAnalysis },
                    { new: true },
                ).exec();

                analyzed++;
                results.push({ eventPlayerId: epId, playerId, aiAnalysis });

            } catch (error: any) {
                failed++;
                results.push({
                    eventPlayerId: epId,
                    playerId,
                    aiAnalysis: null,
                    error: error?.message ?? 'Unknown error',
                });
            }
        }

        return { analyzed, failed, results };
    }

    /**
     * Met à jour la décision de recrutement du coach pour un joueur d'un event.
     */
    async setRecruitmentDecision(
        eventId: string,
        playerId: string,
        decision: boolean,
    ): Promise<EventPlayer> {
        if (!Types.ObjectId.isValid(eventId) || !Types.ObjectId.isValid(playerId)) {
            throw new BadRequestException('Invalid Event or Player ID');
        }

        const ep = await this.eventPlayerModel.findOneAndUpdate(
            {
                eventId: new Types.ObjectId(eventId),
                playerId: new Types.ObjectId(playerId),
            },
            { recruitmentDecision: decision },
            { new: true },
        ).exec();

        if (!ep) {
            throw new NotFoundException('EventPlayer association not found');
        }

        return ep;
    }

    /**
     * Retourne la liste des EventPlayers avec leur analyse IA pour un event.
     */
    async getEventAnalysisResults(eventId: string): Promise<EventPlayer[]> {
        if (!Types.ObjectId.isValid(eventId)) {
            throw new BadRequestException(`Invalid Event ID: ${eventId}`);
        }

        return this.eventPlayerModel
            .find({
                eventId: new Types.ObjectId(eventId),
                aiAnalysis: { $exists: true },
            })
            .populate('playerId')
            .exec();
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    /**
     * Mappe les TestResults d'un joueur vers les métriques attendues par le modèle IA.
     * Les scores normalisés (0–100) sont convertis vers les plages réelles du modèle.
     */
    private mapTestResultsToAiMetrics(testResults: TestResult[], player: any): any {
        const grouped: Record<string, number[]> = {
            speed: [], endurance: [], distance: [], dribbles: [],
            shots: [], injuries: [], heart_rate: [],
        };

        const speedKw = ['speed', 'vitesse', 'sprint', 'acceleration', '30m', '40m'];
        const endKw = ['endurance', 'vo2', 'stamina', 'cooper', 'cardio', 'resistance'];
        const distKw = ['distance', 'covered', 'km'];
        const dribblesKw = ['dribble', 'technique', 'conduite', 'slalom', 'ball'];
        const shotsKw = ['shot', 'finishing', 'tir', 'frappe', 'accuracy'];
        const injKw = ['injury', 'blessure', 'medical', 'douleur'];
        const hrKw = ['heart', 'cardiaque', 'bpm', 'pulse', 'fréquence'];

        const matchesAny = (text: string, kws: string[]) =>
            kws.some(kw => text.toLowerCase().includes(kw));

        for (const tr of testResults) {
            const testType = tr.testTypeId as any;
            const name = (testType?.name ?? '').toLowerCase();
            const category = (testType?.category ?? '').toLowerCase();
            const impactedMetric = (testType?.impactedMetric ?? '').toLowerCase();
            const score = tr.normalizedScore;

            if (impactedMetric === 'speed') grouped.speed.push(score);
            else if (impactedMetric === 'endurance') grouped.endurance.push(score);
            else if (matchesAny(name, speedKw)) grouped.speed.push(score);
            else if (matchesAny(name, endKw)) grouped.endurance.push(score);
            else if (matchesAny(name, distKw)) grouped.distance.push(score);
            else if (matchesAny(name, dribblesKw)) grouped.dribbles.push(score);
            else if (matchesAny(name, shotsKw)) grouped.shots.push(score);
            else if (matchesAny(name, injKw)) grouped.injuries.push(score);
            else if (matchesAny(name, hrKw)) grouped.heart_rate.push(score);
            else if (category === 'medical') grouped.injuries.push(score);
            else if (category === 'technical') grouped.dribbles.push(score);
            else if (category === 'physical') grouped.endurance.push(score);
            else grouped.endurance.push(score); // fallback
        }

        const avg = (arr: number[], fallback: number) =>
            arr.length === 0 ? fallback : arr.reduce((a, b) => a + b, 0) / arr.length;

        const scale = (s: number, min: number, max: number) =>
            Math.round((min + (s / 100) * (max - min)) * 100) / 100;

        const inverseScale = (s: number, min: number, max: number) =>
            Math.round((max - (s / 100) * (max - min)) * 100) / 100;

        const speedScore = avg(grouped.speed, 55);
        const enduranceScore = avg(grouped.endurance, 60);
        const distanceScore = grouped.distance.length > 0
            ? avg(grouped.distance, 60)
            : enduranceScore;
        const dribblesScore = avg(grouped.dribbles, 55);
        const shotsScore = avg(grouped.shots, 50);
        const healthScore = avg(grouped.injuries, 80);
        const cardioScore = grouped.heart_rate.length > 0
            ? avg(grouped.heart_rate, 70)
            : enduranceScore;

        const dateOfBirth = this.toIsoDate(player?.dateOfBirth);

        return {
            firstName: player?.firstName ?? 'Unknown',
            lastName: player?.lastName ?? '',
            ...(dateOfBirth ? { dateOfBirth } : {}),
            age: player?.dateOfBirth
                ? new Date().getFullYear() - new Date(player.dateOfBirth).getFullYear()
                : 20,
            position: player?.position ?? 'Unknown',
            club: 'ODIN Club',
            speed: scale(speedScore, 25, 97),
            endurance: scale(enduranceScore, 25, 97),
            distance: scale(distanceScore, 4.3, 14.6),
            dribbles: Math.round(scale(dribblesScore, 0, 96)),
            shots: Math.round(scale(shotsScore, 0, 49)),
            injuries: Math.round(inverseScale(healthScore, 0, 12)),
            heart_rate: Math.round(inverseScale(cardioScore, 58, 155)),
        };
    }

    private resolveRecruitmentDecision(prediction: any): boolean {
        if (typeof prediction?.should_recruit === 'boolean') return prediction.should_recruit;
        if (typeof prediction?.shouldRecruit === 'boolean') return prediction.shouldRecruit;
        if (typeof prediction?.recruited === 'boolean') return prediction.recruited;
        if (typeof prediction?.recruitment === 'string') {
            return prediction.recruitment.toLowerCase() === 'yes';
        }
        return false;
    }

    private resolveConfidence01(prediction: any): number {
        const raw =
            prediction?.confidence ??
            prediction?.probability ??
            prediction?.confidence_score;

        if (typeof raw !== 'number' || Number.isNaN(raw)) {
            return 0;
        }

        if (raw > 1) {
            return Math.max(0, Math.min(1, raw / 100));
        }

        return Math.max(0, Math.min(1, raw));
    }

    private toIsoDate(value: unknown): string | undefined {
        if (!value) return undefined;
        const d = new Date(value as any);
        if (Number.isNaN(d.getTime())) return undefined;
        return d.toISOString().split('T')[0];
    }
}
