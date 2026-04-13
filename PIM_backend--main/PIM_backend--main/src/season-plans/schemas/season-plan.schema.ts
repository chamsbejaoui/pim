import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type SeasonPlanDocument = SeasonPlan & Document;

@Schema()
export class MicroCycle {
  @Prop({ required: true })
  weekNumber: number;

  @Prop({ required: true, enum: ['HIGH_INTENSITY', 'RECOVERY', 'MAINTENANCE'] })
  focus: string;

  @Prop()
  label: string;

  @Prop()
  objective: string;

  @Prop()
  trainingVolume: string;

  @Prop()
  intensityLevel: string;

  @Prop()
  chargeRpe: number;

  @Prop()
  ratioTravailRepos: string;

  @Prop({ type: [Object], default: [] })
  keyExercises: Record<string, unknown>[];

  @Prop()
  medicalAdvice: string;

  @Prop({ type: [String], default: [] })
  indicateursProgression: string[];

  @Prop()
  nutritionRecommandee: string;

  @Prop({ default: false })
  sessionVideoTactique: boolean;

  @Prop()
  startDate: Date;

  @Prop()
  endDate: Date;
}
export const MicroCycleSchema = SchemaFactory.createForClass(MicroCycle);


@Schema()
export class MesoCycle {
  @Prop({ required: true })
  name: string;

  @Prop()
  objective: string;

  @Prop()
  startDate: Date;

  @Prop()
  endDate: Date;

  @Prop({ type: [MicroCycleSchema], default: [] })
  microCycles: MicroCycle[];
}
export const MesoCycleSchema = SchemaFactory.createForClass(MesoCycle);

@Schema()
export class MacroCycle {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true, enum: ['PRE_SEASON', 'COMPETITION', 'REST'] })
  type: string;

  @Prop()
  startDate: Date;

  @Prop()
  endDate: Date;

  @Prop({ type: [MesoCycleSchema], default: [] })
  mesoCycles: MesoCycle[];
}
export const MacroCycleSchema = SchemaFactory.createForClass(MacroCycle);

@Schema()
export class CollectivePreparation {
  @Prop()
  competitionName: string;

  @Prop()
  gameModel: string;

  @Prop()
  primaryObjective: string;

  @Prop({ type: [String], default: [] })
  secondaryObjectives: string[];

  @Prop({ type: [String], default: [] })
  tacticalPrinciples: string[];

  @Prop({ type: [String], default: [] })
  culturalPrinciples: string[];

  @Prop({ min: 0, max: 100, default: 85 })
  targetAvailabilityPct: number;

  @Prop({ min: 0, max: 10, default: 7 })
  targetCohesionScore: number;

  @Prop({ min: 0, max: 10, default: 7 })
  targetTacticalAssimilation: number;
}
export const CollectivePreparationSchema = SchemaFactory.createForClass(CollectivePreparation);

@Schema()
export class WeeklyCollectiveCheckin {
  @Prop({ required: true })
  weekNumber: number;

  @Prop()
  date: Date;

  @Prop({ min: 0, max: 10 })
  physicalLoad: number;

  @Prop({ min: 0, max: 10 })
  tacticalAssimilation: number;

  @Prop({ min: 0, max: 10 })
  teamCohesion: number;

  @Prop({ min: 0, max: 10 })
  morale: number;

  @Prop({ min: 0, default: 0 })
  injuries: number;

  @Prop({ min: 0, max: 10 })
  fatigue: number;

  @Prop()
  coachNotes: string;

  @Prop({ type: [String], default: [] })
  actionItems: string[];
}
export const WeeklyCollectiveCheckinSchema = SchemaFactory.createForClass(WeeklyCollectiveCheckin);

@Schema({ timestamps: true })
export class SeasonPlan {
  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  year: string;

  @Prop()
  startDate: Date;

  @Prop()
  endDate: Date;

  @Prop({ type: String })
  teamId?: string;

  @Prop({ type: CollectivePreparationSchema, default: {} })
  collectivePreparation: CollectivePreparation;

  @Prop({ type: [WeeklyCollectiveCheckinSchema], default: [] })
  weeklyCheckins: WeeklyCollectiveCheckin[];

  @Prop({ type: [MacroCycleSchema], default: [] })
  macroCycles: MacroCycle[];
}

export const SeasonPlanSchema = SchemaFactory.createForClass(SeasonPlan);
