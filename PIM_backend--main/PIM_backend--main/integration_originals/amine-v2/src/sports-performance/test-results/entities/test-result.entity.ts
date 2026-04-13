import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type TestResultDocument = TestResult & Document;

@Schema({ timestamps: true })
export class TestResult {
    @Prop({ type: Types.ObjectId, ref: 'EventPlayer', required: true })
    eventPlayerId: Types.ObjectId;

    @Prop({ type: Types.ObjectId, ref: 'TestType', required: true })
    testTypeId: Types.ObjectId;

    @Prop({ required: true })
    rawValue: number; // Valeur brute mesurée

    @Prop({ required: true, min: 0, max: 100 })
    normalizedScore: number; // Score normalisé 0-100

    @Prop()
    notes?: string;

    @Prop({ type: Types.ObjectId, ref: 'User' })
    recordedBy: Types.ObjectId;

    @Prop({ default: Date.now })
    recordedAt: Date;
}

export const TestResultSchema = SchemaFactory.createForClass(TestResult);

// Index pour requêtes fréquentes
TestResultSchema.index({ eventPlayerId: 1, testTypeId: 1 });
