import { IsString, IsEnum, IsNumber, IsBoolean, IsOptional, IsArray, Min, Max, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { ExerciseCategory, IntensityLevel, PitchPosition } from '../entities/exercise.entity';

class TechnicalDataDto {
    @IsString()
    @IsOptional()
    description?: string;

    @IsNumber()
    @IsOptional()
    sets?: number;

    @IsNumber()
    @IsOptional()
    reps?: number;

    @IsArray()
    @IsString({ each: true })
    @IsOptional()
    coachingCues?: string[];

    @IsArray()
    @IsString({ each: true })
    @IsOptional()
    steps?: string[];

    @IsArray()
    @IsString({ each: true })
    @IsOptional()
    equipment?: string[];

    @IsString()
    @IsOptional()
    restTime?: string;
}

class PerformanceImpactDto {
    @IsNumber()
    @IsOptional()
    speed?: number;

    @IsNumber()
    @IsOptional()
    endurance?: number;

    @IsNumber()
    @IsOptional()
    technique?: number;
}

export class CreateExerciseDto {
    @IsString()
    name: string;

    @IsEnum(ExerciseCategory)
    category: ExerciseCategory;

    @IsNumber()
    @Min(1)
    @Max(5)
    difficulty: number;

    @IsNumber()
    @Min(1)
    duration: number;

    @IsEnum(IntensityLevel)
    intensity: IntensityLevel;

    @IsArray()
    @IsEnum(PitchPosition, { each: true })
    targetPositions: PitchPosition[];

    @IsBoolean()
    @IsOptional()
    aiGenerated?: boolean;

    @IsOptional()
    @ValidateNested()
    @Type(() => TechnicalDataDto)
    technicalData?: TechnicalDataDto;

    @IsOptional()
    @ValidateNested()
    @Type(() => PerformanceImpactDto)
    performanceImpact?: PerformanceImpactDto;

    @IsString()
    @IsOptional()
    imageUrl?: string;
}
