import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class PhysicalProfile extends Document {
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true, type: Number })
  weightKg: number;

  @Prop({ required: true, type: Number })
  heightCm: number;

  @Prop({ required: true, type: Number })
  tourTaille: number;

  @Prop({ required: true, type: Number })
  tourCou: number;

  @Prop({ required: true, type: Date })
  dateNaissance: Date;

  @Prop({ required: true })
  position: string;
}

export const PhysicalProfileSchema = SchemaFactory.createForClass(PhysicalProfile);
