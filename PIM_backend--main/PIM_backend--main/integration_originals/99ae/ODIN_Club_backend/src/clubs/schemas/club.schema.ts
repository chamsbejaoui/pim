import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import { ClubStatus } from '../../common/enums/club-status.enum';

export type ClubDocument = HydratedDocument<Club>;

@Schema({ collection: 'clubs', timestamps: true })
export class Club {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  league: string;

  @Prop()
  country?: string;

  @Prop()
  city?: string;

  @Prop()
  logoUrl?: string;

  @Prop({ type: String, enum: ClubStatus, default: ClubStatus.PENDING, index: true })
  status: ClubStatus;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  createdByUserId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  responsableUserId?: Types.ObjectId;
}

export const ClubSchema = SchemaFactory.createForClass(Club);

ClubSchema.index({ status: 1, createdAt: -1 });
