import {
  IsString,
  IsOptional,
  IsDateString,
  IsArray,
  ValidateNested,
  IsNumber,
  IsInt,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateMicroCycleDto {
  @IsNumber()
  weekNumber: number;

  @IsString()
  focus: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;
}

export class CreateCollectivePreparationDto {
  @IsOptional()
  @IsString()
  competitionName?: string;

  @IsOptional()
  @IsString()
  gameModel?: string;

  @IsOptional()
  @IsString()
  primaryObjective?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  secondaryObjectives?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tacticalPrinciples?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  culturalPrinciples?: string[];

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  targetAvailabilityPct?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(10)
  targetCohesionScore?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(10)
  targetTacticalAssimilation?: number;
}

export class CreateWeeklyCollectiveCheckinDto {
  @IsInt()
  @Min(1)
  weekNumber: number;

  @IsOptional()
  @IsDateString()
  date?: string;

  @IsNumber()
  @Min(0)
  @Max(10)
  physicalLoad: number;

  @IsNumber()
  @Min(0)
  @Max(10)
  tacticalAssimilation: number;

  @IsNumber()
  @Min(0)
  @Max(10)
  teamCohesion: number;

  @IsNumber()
  @Min(0)
  @Max(10)
  morale: number;

  @IsInt()
  @Min(0)
  injuries: number;

  @IsNumber()
  @Min(0)
  @Max(10)
  fatigue: number;

  @IsOptional()
  @IsString()
  coachNotes?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  actionItems?: string[];
}

export class CreateMesoCycleDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  objective?: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateMicroCycleDto)
  microCycles?: CreateMicroCycleDto[];
}

export class CreateMacroCycleDto {
  @IsString()
  name: string;

  @IsString()
  type: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateMesoCycleDto)
  mesoCycles?: CreateMesoCycleDto[];
}

export class CreateSeasonPlanDto {
  @IsString()
  title: string;

  @IsString()
  year: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsString()
  teamId?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => CreateCollectivePreparationDto)
  collectivePreparation?: CreateCollectivePreparationDto;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateWeeklyCollectiveCheckinDto)
  weeklyCheckins?: CreateWeeklyCollectiveCheckinDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateMacroCycleDto)
  macroCycles?: CreateMacroCycleDto[];
}
