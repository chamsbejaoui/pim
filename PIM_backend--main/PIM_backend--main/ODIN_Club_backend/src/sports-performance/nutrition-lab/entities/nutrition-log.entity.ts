import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum MealType {
  PRE_MATCH = 'PRE_MATCH',
  POST_MATCH_RECOVERY = 'POST_MATCH_RECOVERY',
  HIGH_CARB = 'HIGH_CARB',
  MAINTENANCE = 'MAINTENANCE',
  HYDRATION = 'HYDRATION'
}

@Schema({ timestamps: true })
export class NutritionLog extends Document {
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true, enum: MealType })
  mealType: string;

  @Prop({ default: 0, type: Number })
  carbsGrams: number;

  @Prop({ default: 0, type: Number })
  proteinsGrams: number;

  @Prop({ default: 0, type: Number })
  fatsGrams: number;

  @Prop({ default: 0, type: Number })
  hydrationMl: number;
}

export const NutritionLogSchema = SchemaFactory.createForClass(NutritionLog);
