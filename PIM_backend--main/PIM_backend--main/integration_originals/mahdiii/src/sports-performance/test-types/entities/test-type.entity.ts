import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type TestTypeDocument = TestType & Document;

export enum TestCategory {
    PHYSICAL = 'physical',
    TECHNICAL = 'technical',
    MEDICAL = 'medical',
    MENTAL = 'mental',
}

export enum ScoringMethod {
    HIGHER_BETTER = 'higher_better', // Plus c'est élevé, mieux c'est (ex: vitesse max)
    LOWER_BETTER = 'lower_better',   // Plus c'est bas, mieux c'est (ex: temps au sprint)
    RANGE = 'range',                 // Dans une plage optimale
}

export enum PerformanceMetric {
    SPEED = 'speed',
    ENDURANCE = 'endurance',
    TECHNIQUE = 'technique',
    TACTICAL = 'tactical',
    COGNITIVE = 'cognitive',
}

@Schema({ timestamps: true })
export class TestType {
    @Prop({ required: true, unique: true })
    name: string;

    @Prop({ type: String, enum: TestCategory, required: true })
    category: TestCategory;

    @Prop({ type: String, enum: PerformanceMetric })
    impactedMetric?: PerformanceMetric;

    @Prop()
    description?: string;

    @Prop({ required: true })
    unit: string; // secondes, mètres, kg, etc.

    @Prop({ type: String, enum: ScoringMethod, required: true })
    scoringMethod: ScoringMethod;

    @Prop()
    minValue?: number;

    @Prop()
    maxValue?: number;

    @Prop({
        type: {
            min: Number,
            max: Number,
        },
    })
    optimalRange?: {
        min: number;
        max: number;
    };

    @Prop({ default: 1, min: 0.1, max: 10 })
    weight: number; // Importance du test dans le calcul global (1 = normal)

    @Prop()
    eliteThreshold?: number; // Benchmark pour performance d'élite (ex: 3.70s pour sprint 30m)

    @Prop()
    baselineThreshold?: number; // Seuil minimum acceptable (ex: 5.00s pour sprint 30m)

    @Prop({ default: true })
    isActive: boolean;
}

export const TestTypeSchema = SchemaFactory.createForClass(TestType);
