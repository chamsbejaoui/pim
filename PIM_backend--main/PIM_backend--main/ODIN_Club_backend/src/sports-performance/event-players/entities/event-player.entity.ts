import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type EventPlayerDocument = EventPlayer & Document;

export enum ParticipationStatus {
    INVITED = 'invited',
    CONFIRMED = 'confirmed',
    COMPLETED = 'completed',
    ABSENT = 'absent',
}

export class AiAnalysisResult {
    recruited: boolean;
    confidence: number; // 0.0 – 1.0
    cluster?: string;   // 'Elite', 'Average', etc.
    potentialScore?: number;
    shap?: Record<string, number>;
    analyzedAt: Date;
    /** Real computed stats from TestResults — used by Flutter AI module */
    metrics?: {
        speed: number;
        endurance: number;
        distance: number;
        dribbles: number;
        shots: number;
        injuries: number;
        heart_rate: number;
    };
}

@Schema({ timestamps: true })
export class EventPlayer {
    @Prop({ type: Types.ObjectId, ref: 'Event', required: true })
    eventId: Types.ObjectId;

    @Prop({ type: Types.ObjectId, ref: 'Player', required: true })
    playerId: Types.ObjectId;

    @Prop({ type: String, enum: ParticipationStatus, default: ParticipationStatus.INVITED })
    status: ParticipationStatus;

    @Prop()
    coachNotes?: string;

    @Prop({ default: Date.now })
    joinedAt: Date;

    @Prop()
    completedAt?: Date;

    /** Résultat de l'analyse IA (stocké après POST /events/:id/analyze) */
    @Prop({ type: Object })
    aiAnalysis?: AiAnalysisResult;

    /** Décision finale du coach après analyse IA */
    @Prop({ type: Boolean })
    recruitmentDecision?: boolean;
}

export const EventPlayerSchema = SchemaFactory.createForClass(EventPlayer);

// Index composé pour éviter les doublons
EventPlayerSchema.index({ eventId: 1, playerId: 1 }, { unique: true });
