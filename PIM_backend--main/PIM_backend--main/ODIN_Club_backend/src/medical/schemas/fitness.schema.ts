import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";

export type FitnessSnapshotDocument = FitnessSnapshot & Document;

@Schema({ timestamps: true, collection: "fitness_snapshots" })
export class FitnessSnapshot {
  @Prop({ required: true, index: true })
  providerName: string;

  @Prop({ required: true, index: true })
  providerPlayerId: string;

  @Prop({ required: true })
  acuteLoad: number;

  @Prop({ required: true })
  chronicLoad: number;

  @Prop({ required: true })
  loadRatio: number;

  @Prop({ required: true })
  fitnessScore: number;

  @Prop({ required: true })
  fatigueScore: number;

  @Prop({ required: true })
  lastUpdated: string;
}

export const FitnessSnapshotSchema = SchemaFactory.createForClass(FitnessSnapshot);
FitnessSnapshotSchema.index({ providerName: 1, providerPlayerId: 1 }, { unique: true });
