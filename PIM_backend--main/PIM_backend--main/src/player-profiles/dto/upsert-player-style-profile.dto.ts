import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class UpsertPlayerStyleProfileDto {
  @ApiPropertyOptional({ example: '2026-2027' })
  @IsOptional()
  @IsString()
  season?: string;

  @ApiPropertyOptional({ example: 7, minimum: 0, maximum: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(10)
  possessionPlay?: number;

  @ApiPropertyOptional({ example: 3, minimum: 0, maximum: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(10)
  selfishness?: number;

  @ApiPropertyOptional({ example: 8, minimum: 0, maximum: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(10)
  oneTouchPreference?: number;

  @ApiPropertyOptional({ example: 6, minimum: 0, maximum: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(10)
  directPlay?: number;

  @ApiPropertyOptional({ example: 5, minimum: 0, maximum: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(10)
  riskTaking?: number;

  @ApiPropertyOptional({ example: 7, minimum: 0, maximum: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(10)
  pressingIntensity?: number;

  @ApiPropertyOptional({ example: 8, minimum: 0, maximum: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(10)
  offBallMovement?: number;

  @ApiPropertyOptional({ example: 6, minimum: 0, maximum: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(10)
  communication?: number;

  @ApiPropertyOptional({ example: 8, minimum: 0, maximum: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(10)
  defensiveDiscipline?: number;

  @ApiPropertyOptional({ example: 7, minimum: 0, maximum: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(10)
  creativity?: number;

  @ApiPropertyOptional({ type: [String], example: ['possession', 'short-passes'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  preferredStyles?: string[];

  @ApiPropertyOptional({ example: 'Prefers quick one-touch combinations in right half-space.' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ example: 'Head Coach' })
  @IsOptional()
  @IsString()
  updatedBy?: string;
}
