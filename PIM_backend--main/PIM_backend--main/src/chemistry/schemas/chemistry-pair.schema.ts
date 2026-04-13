import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ChemistryPairDocument = HydratedDocument<ChemistryPair>;

@Schema({ timestamps: true, collection: 'chemistry_pairs' })
export class ChemistryPair {
  @Prop({ required: true, index: true })
  season: string;

  @Prop({ type: Types.ObjectId, ref: 'Player', required: true, index: true })
  playerAId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Player', required: true, index: true })
  playerBId: Types.ObjectId;

  @Prop({ required: true, index: true })
  pairKey: string;

  @Prop({ required: true, min: 0, max: 10 })
  averageRating: number;

  @Prop({ required: true, min: 0, max: 10 })
  lastRating: number;

  @Prop({ required: true, min: 0, default: 0 })
  observationCount: number;

  @Prop({ required: false, min: 0, max: 10 })
  aiScore?: number;

  @Prop({ required: false })
  aiScoreVersion?: string;

  @Prop({ required: false })
  aiScoreComputedAt?: Date;

  @Prop({ required: false, min: 0, max: 10 })
  manualScore?: number;

  @Prop({ required: false })
  manualScoreBy?: string;

  @Prop({ required: false })
  manualScoreReason?: string;

  @Prop({ required: false })
  manualScoreUpdatedAt?: Date;

  @Prop({ required: false })
  observedBy?: string;

  @Prop({ required: false })
  tacticalZone?: string;

  @Prop({ required: false })
  notes?: string;

  @Prop({ default: Date.now })
  lastObservedAt?: Date;
}

export const ChemistryPairSchema = SchemaFactory.createForClass(ChemistryPair);
ChemistryPairSchema.index({ season: 1, pairKey: 1 }, { unique: true });
ChemistryPairSchema.index({ season: 1, averageRating: -1 });
ChemistryPairSchema.index({ season: 1, playerAId: 1, playerBId: 1 });
ChemistryPairSchema.index({ season: 1, manualScore: -1, aiScore: -1, averageRating: -1 });
