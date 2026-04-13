import { IsEnum, IsNumber, IsString, IsNotEmpty, IsOptional } from 'class-validator';
import { MealType } from '../entities/nutrition-log.entity';

export class LogNutritionDto {
  @IsString()
  @IsNotEmpty()
  userId: string;

  @IsEnum(MealType)
  mealType: MealType;

  @IsOptional()
  @IsNumber()
  carbsGrams?: number;

  @IsOptional()
  @IsNumber()
  proteinsGrams?: number;

  @IsOptional()
  @IsNumber()
  fatsGrams?: number;

  @IsOptional()
  @IsNumber()
  hydrationMl?: number;
}
