import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsMongoId, IsOptional, IsString } from 'class-validator';

export class AnalyzePairProfileDto {
  @ApiProperty({ example: '2026-2027' })
  @IsString()
  season: string;

  @ApiProperty({ example: '65d31f4b4ec6f6fcb18d6a11' })
  @IsMongoId()
  playerAId: string;

  @ApiProperty({ example: '65d31f4b4ec6f6fcb18d6a12' })
  @IsMongoId()
  playerBId: string;

  @ApiPropertyOptional({ example: true, default: true })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  includeAiInsights?: boolean;
}
