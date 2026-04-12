import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { ArrayMaxSize, ArrayMinSize, IsArray, IsBoolean, IsOptional, IsString } from 'class-validator';

export class AnalyzeSquadProfileDto {
  @ApiPropertyOptional({ example: '2026-2027' })
  @IsOptional()
  @IsString()
  season?: string;

  @ApiPropertyOptional({
    type: [String],
    example: ['4-3-3', '4-2-3-1', '3-5-2'],
    description: 'Optional list of formations to compare before selecting the best one.'
  })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(8)
  @IsString({ each: true })
  formations?: string[];

  @ApiPropertyOptional({ example: true, default: true })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  includeAiInsights?: boolean;
}
