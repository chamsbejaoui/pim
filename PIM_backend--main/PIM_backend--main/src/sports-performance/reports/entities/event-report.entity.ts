import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type EventReportDocument = EventReport & Document;

@Schema({ timestamps: true })
export class EventReport {
    @Prop({ type: Types.ObjectId, ref: 'Event', required: true, unique: true })
    eventId: Types.ObjectId;

    @Prop({ required: true })
    totalPlayers: number;

    @Prop({ required: true })
    completedTests: number;

    @Prop({ required: true })
    averageScore: number;

    @Prop({
        type: [
            {
                playerId: { type: Types.ObjectId, ref: 'Player' },
                eventPlayerId: { type: Types.ObjectId, ref: 'EventPlayer' },
                score: Number,
                rank: Number,
            },
        ],
        default: [],
    })
    topPlayers: Array<{
        playerId: Types.ObjectId;
        eventPlayerId: Types.ObjectId;
        score: number;
        rank: number;
        scoreTrend: number;
    }>;

    @Prop({
        type: [
            {
                playerId: { type: Types.ObjectId, ref: 'Player' },
                eventPlayerId: { type: Types.ObjectId, ref: 'EventPlayer' },
                score: Number,
                rank: Number,
            },
        ],
        default: [],
    })
    ranking: Array<{
        playerId: Types.ObjectId;
        eventPlayerId: Types.ObjectId;
        score: number;
        rank: number;
        scoreTrend: number;
    }>;

    @Prop({ type: Object, default: {} })
    statistics: {
        byCategory?: Map<string, { avg: number; min: number; max: number }>;
        distribution?: any;
    };

    @Prop({ default: Date.now })
    generatedAt: Date;
}

export const EventReportSchema = SchemaFactory.createForClass(EventReport);
