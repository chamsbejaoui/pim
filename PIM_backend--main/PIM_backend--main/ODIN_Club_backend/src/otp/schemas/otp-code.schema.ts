import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type OtpCodeDocument = HydratedDocument<OtpCode>;

@Schema({ collection: 'otp_codes', timestamps: true })
export class OtpCode {
  @Prop({ required: true, lowercase: true, index: true })
  email: string;

  @Prop({ type: Types.ObjectId, ref: 'User', required: false, index: true })
  userId?: Types.ObjectId;

  @Prop({ required: true, index: true })
  purpose: string;

  @Prop({ required: true })
  codeHash: string;

  @Prop({ required: true, index: true })
  expiresAt: Date;

  @Prop()
  consumedAt?: Date;
}

export const OtpCodeSchema = SchemaFactory.createForClass(OtpCode);

OtpCodeSchema.index({ email: 1, purpose: 1, consumedAt: 1, expiresAt: -1 });
