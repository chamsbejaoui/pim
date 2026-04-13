import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsMongoId,
  IsOptional,
  IsString,
  Max,
  Min
} from 'class-validator';

export class GenerateStartingXiDto {
  @ApiPropertyOptional({ example: '2026-2027' })
  @IsOptional()
  @IsString()
  season?: string;

  @ApiPropertyOptional({
    example: '4-3-3',
    description: 'Formation lines without goalkeeper. Sum must be 10 (e.g. 4-2-3-1, 3-5-2).'
  })
  @IsOptional()
  @IsString()
  formation?: string;

  @ApiPropertyOptional({
    type: [String],
    minItems: 11,
    maxItems: 120,
    description: 'Optional pool of players to consider for XI generation.'
  })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(11)
  @ArrayMaxSize(120)
  @IsMongoId({ each: true })
  candidatePlayerIds?: string[];

  @ApiPropertyOptional({ example: 60, minimum: 11, maximum: 120, default: 60 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(11)
  @Max(120)
  poolLimit?: number;

  @ApiPropertyOptional({ example: true, default: true })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  includeAiInsights?: boolean;
}
