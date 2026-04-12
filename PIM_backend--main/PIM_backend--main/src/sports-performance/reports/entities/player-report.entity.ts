import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type PlayerReportDocument = PlayerReport & Document;

@Schema({ timestamps: true })
export class PlayerReport {
    @Prop({ type: Types.ObjectId, ref: 'EventPlayer', required: true, unique: true })
    eventPlayerId: Types.ObjectId;

    @Prop({ required: true, min: 0, max: 100 })
    overallScore: number;

    @Prop({ required: true, min: 1 })
    rank: number;

    @Prop({ required: true })
    totalPlayers: number;

    @Prop({ required: true })
    eventAverage: number;

    @Prop({ required: true })
    deviation: number; // Écart par rapport à la moyenne

    @Prop({ default: 0 })
    scoreTrend: number; // Évolution par rapport à la session précédente (ex: +1.2 ou -0.4)

    @Prop({
        type: [
            {
                testTypeId: { type: Types.ObjectId, ref: 'TestType' },
                testName: String,
                score: Number,
                category: String,
            },
        ],
        default: [],
    })
    testScores: Array<{
        testTypeId: Types.ObjectId;
        testName: string;
        score: number;
        category: string;
    }>;

    @Prop({ type: [String], default: [] })
    strengths: string[];

    @Prop({ type: [String], default: [] })
    weaknesses: string[];

    @Prop()
    recommendation?: string;

    @Prop({ default: false })
    isTopPlayer: boolean;

    @Prop({ default: Date.now })
    generatedAt: Date;
}

export const PlayerReportSchema = SchemaFactory.createForClass(PlayerReport);
