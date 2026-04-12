import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsMongoId,
  IsOptional,
  IsString,
  ValidateNested
} from 'class-validator';

export class LineupPlayerDto {
  @ApiProperty({ example: '65d31f4b4ec6f6fcb18d6a11' })
  @IsMongoId()
  playerId: string;

  @ApiPropertyOptional({ example: 'AM' })
  @IsOptional()
  @IsString()
  position?: string;
}

export class ScoreLineupDto {
  @ApiPropertyOptional({ example: '2026-2027' })
  @IsOptional()
  @IsString()
  season?: string;

  @ApiPropertyOptional({
    type: [String],
    minItems: 3,
    maxItems: 11,
    description: 'Alternative input format: array of player IDs.'
  })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(3)
  @ArrayMaxSize(11)
  @IsMongoId({ each: true })
  playerIds?: string[];

  @ApiPropertyOptional({
    type: [LineupPlayerDto],
    minItems: 3,
    maxItems: 11,
    description: 'Preferred input format: lineup with optional role overrides.'
  })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(3)
  @ArrayMaxSize(11)
  @ValidateNested({ each: true })
  @Type(() => LineupPlayerDto)
  players?: LineupPlayerDto[];

  @ApiPropertyOptional({ example: false, default: false })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  includeAiInsights?: boolean;
}
