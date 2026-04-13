import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type PlayerDocument = Player & Document;

@Schema({ timestamps: true, collection: 'players' })
export class Player {
  @Prop({ type: Types.ObjectId, ref: 'User', required: false })
  userId?: Types.ObjectId;

  @Prop({ required: false, index: true })
  providerName?: string;

  @Prop({ required: false, index: true })
  providerPlayerId?: string;

  @Prop({ required: false })
  name?: string;

  @Prop({ required: false })
  firstName?: string;

  @Prop({ required: false })
  lastName?: string;

  @Prop({ required: false })
  age?: number;

  @Prop({ required: false })
  position?: string;

  @Prop({ required: false })
  dateOfBirth?: Date;

  @Prop({ required: false })
  strongFoot?: string;

  @Prop({ required: false })
  jerseyNumber?: number;

  @Prop({ required: false })
  height?: number;

  @Prop({ required: false })
  weight?: number;

  @Prop({ required: false })
  photo?: string;

  @Prop({ required: false })
  nationality?: string;

  @Prop({ default: 0, min: 0, max: 100 })
  speed?: number;

  @Prop({ default: 0, min: 0, max: 100 })
  endurance?: number;

  @Prop({ default: 0, min: 0 })
  distance?: number;

  @Prop({ default: 0, min: 0 })
  dribbles?: number;

  @Prop({ default: 0, min: 0 })
  shots?: number;

  @Prop({ default: 0, min: 0 })
  injuries?: number;

  @Prop({ default: 0, min: 0 })
  heart_rate?: number;

  @Prop({ default: null })
  label?: number;

  @Prop({ default: 'active' })
  status?: string;

  @Prop({
    type: {
      totalEvents: { type: Number, default: 0 },
      averageScore: { type: Number, default: 0 },
      bestScore: { type: Number, default: 0 },
      rank: { type: String, default: 'N/A' }
    },
    default: {}
  })
  statistics?: {
    totalEvents: number;
    averageScore: number;
    bestScore: number;
    rank: string;
  };

  @Prop({ default: 75 })
  baseFitness?: number;

  @Prop({ default: 0 })
  injuryHistory?: number;

  @Prop({ default: false })
  isInjured?: boolean;

  @Prop()
  lastInjuryType?: string;

  @Prop()
  lastRecoveryDays?: number;

  @Prop()
  lastSeverity?: string;

  @Prop()
  lastInjuryProbability?: number;

  @Prop()
  lastMatchId?: string;

  @Prop()
  lastMatchAt?: Date;

  @Prop()
  lastMatchLoad?: number;

  @Prop()
  lastMatchFatigue?: number;

  @Prop()
  lastMatchInjuryProbability?: number;
}

export const PlayerSchema = SchemaFactory.createForClass(Player);
PlayerSchema.index({ providerName: 1, providerPlayerId: 1 }, { unique: true, sparse: true });
