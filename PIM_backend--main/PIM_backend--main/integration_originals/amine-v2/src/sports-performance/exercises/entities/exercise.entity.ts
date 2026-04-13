import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum ExerciseCategory {
    PHYSICAL = 'Physical',
    TECHNICAL = 'Technical',
    TACTICAL = 'Tactical',
    COGNITIVE = 'Cognitive',
}

export enum IntensityLevel {
    LOW = 'Low',
    MEDIUM = 'Medium',
    HIGH = 'High',
}

export enum PitchPosition {
    GK = 'GK',
    DEF = 'DEF',
    MID = 'MID',
    ATT = 'ATT',
}

@Schema({ _id: false })
class TechnicalData {
    @Prop({ type: String })
    description: string;

    @Prop({ type: String })
    sets: string;

    @Prop({ type: String })
    reps: string;

    @Prop({ type: [String] })
    coachingCues: string[];

    @Prop({ type: [String] })
    equipment: string[];

    @Prop({ type: [String] })
    steps: string[];

    @Prop({ type: String })
    restTime: string;
}

@Schema({ _id: false })
class PerformanceImpact {
    @Prop({ type: Number, default: 0 })
    speed: number;

    @Prop({ type: Number, default: 0 })
    endurance: number;

    @Prop({ type: Number, default: 0 })
    technique: number;
}

@Schema({ _id: false })
class GenerationContext {
    @Prop({ type: String })
    objective: string;

    @Prop({ type: Number })
    playerFatigueAtGeneration: number;

    @Prop({ type: String })
    aiModelUsed: string;

    @Prop({ type: Number })
    aiConfidenceScore: number;
}

@Schema({ _id: false })
class CompletedSession {
    @Prop({ type: String })
    playerId: string;

    @Prop({ type: Date, default: Date.now })
    completedAt: Date;

    @Prop({ type: Number })
    durationSeconds: number;

    @Prop({ type: Number, default: 0 })
    lapsCount: number;
}

@Schema({ timestamps: true })
export class Exercise {
    @Prop({ required: true })
    name: string;

    @Prop({ type: String, enum: ExerciseCategory, required: true })
    category: ExerciseCategory;

    @Prop({ type: Number, min: 1, max: 5, required: true })
    difficulty: number;

    @Prop({ type: Number, required: true })
    duration: number;

    @Prop({ type: String, enum: IntensityLevel, required: true })
    intensity: IntensityLevel;

    @Prop({ type: [String], enum: PitchPosition, required: true })
    targetPositions: PitchPosition[];

    @Prop({ type: Boolean, default: false })
    aiGenerated: boolean;

    @Prop({ type: GenerationContext })
    generationContext: GenerationContext;

    @Prop({ type: TechnicalData })
    technicalData: TechnicalData;

    @Prop({ type: PerformanceImpact })
    performanceImpact: PerformanceImpact;

    @Prop({ type: String })
    imageUrl: string;

    @Prop({ type: [Object], default: [] })
    completedSessions: CompletedSession[];
}

export type ExerciseDocument = Exercise & Document;
export const ExerciseSchema = SchemaFactory.createForClass(Exercise);
