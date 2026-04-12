import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Min,
  ValidateNested
} from 'class-validator';

export class GoalDirectionOverrideDto {
  @IsString()
  teamName: string;

  @IsIn(['left', 'right'])
  direction: 'left' | 'right';
}

export class CreateAnalysisJobDto {
  @IsOptional()
  @IsString()
  videoPath?: string;

  @IsOptional()
  @IsString()
  videoUrl?: string;

  @IsString()
  team1Name: string;

  @IsString()
  team1ShirtColor: string;

  @IsString()
  team2Name: string;

  @IsString()
  team2ShirtColor: string;

  @IsOptional()
  @IsBoolean()
  enableOffside?: boolean;

  @IsOptional()
  @IsIn(['balanced', 'best'])
  analysisPreset?: 'balanced' | 'best';

  @IsOptional()
  @IsIn(['simple', 'bytetrack'])
  trackerBackend?: 'simple' | 'bytetrack';

  @IsOptional()
  @IsString()
  yoloWeights?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  frameStride?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  maxFrames?: number;

  @IsOptional()
  @IsString()
  outputJsonPath?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => GoalDirectionOverrideDto)
  goalDirectionOverrides?: GoalDirectionOverrideDto[];
}

