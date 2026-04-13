import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type PlayerStyleProfileDocument = HydratedDocument<PlayerStyleProfile>;

@Schema({ timestamps: true, collection: 'player_style_profiles' })
export class PlayerStyleProfile {
  @Prop({ required: true, index: true })
  season: string;

  @Prop({ type: Types.ObjectId, ref: 'Player', required: true, index: true })
  playerId: Types.ObjectId;

  @Prop({ required: true, min: 0, max: 10, default: 5 })
  possessionPlay: number;

  @Prop({ required: true, min: 0, max: 10, default: 5 })
  selfishness: number;

  @Prop({ required: true, min: 0, max: 10, default: 5 })
  oneTouchPreference: number;

  @Prop({ required: true, min: 0, max: 10, default: 5 })
  directPlay: number;

  @Prop({ required: true, min: 0, max: 10, default: 5 })
  riskTaking: number;

  @Prop({ required: true, min: 0, max: 10, default: 5 })
  pressingIntensity: number;

  @Prop({ required: true, min: 0, max: 10, default: 5 })
  offBallMovement: number;

  @Prop({ required: true, min: 0, max: 10, default: 5 })
  communication: number;

  @Prop({ required: true, min: 0, max: 10, default: 5 })
  defensiveDiscipline: number;

  @Prop({ required: true, min: 0, max: 10, default: 5 })
  creativity: number;

  @Prop({ type: [String], default: [] })
  preferredStyles: string[];

  @Prop({ required: false })
  notes?: string;

  @Prop({ required: false })
  updatedBy?: string;
}

export const PlayerStyleProfileSchema = SchemaFactory.createForClass(PlayerStyleProfile);
PlayerStyleProfileSchema.index({ season: 1, playerId: 1 }, { unique: true });
PlayerStyleProfileSchema.index({ season: 1, updatedAt: -1 });
