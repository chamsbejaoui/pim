import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type SquadDocument = Squad & Document;

@Schema({ timestamps: true, collection: 'squads' })
export class Squad {
  @Prop({ required: true, index: true })
  season: string;

  @Prop({ required: false })
  label?: string;

  @Prop({ type: [{ type: Types.ObjectId, ref: 'Player' }], required: true })
  playerIds: Types.ObjectId[];

  @Prop({ type: [{ type: Types.ObjectId, ref: 'Player' }], required: true })
  starterIds: Types.ObjectId[];

  @Prop({ type: [{ type: Types.ObjectId, ref: 'Player' }], required: true })
  benchIds: Types.ObjectId[];

  @Prop({ type: [{ type: Types.ObjectId, ref: 'Player' }], required: true })
  reserveIds: Types.ObjectId[];

  @Prop({ default: 24 })
  targetSquadSize: number;
}

export const SquadSchema = SchemaFactory.createForClass(Squad);
SquadSchema.index({ season: 1 }, { unique: true });
