import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested
} from 'class-validator';

export class OpponentPlayerStatsDto {
  @ApiPropertyOptional({ example: 7.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(10)
  rating?: number;

  @ApiPropertyOptional({ example: 12 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  goals?: number;

  @ApiPropertyOptional({ example: 8 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  assists?: number;

  @ApiPropertyOptional({ example: 38 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  shots?: number;

  @ApiPropertyOptional({ example: 1150 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  passes?: number;

  @ApiPropertyOptional({ example: 44 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  tackles?: number;

  @ApiPropertyOptional({ example: 1620 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  minutes?: number;
}

export class OpponentPlayerDto {
  @ApiProperty({ example: 'A. Hakimi' })
  @IsString()
  name: string;

  @ApiProperty({ example: 'RB' })
  @IsString()
  position: string;

  @ApiPropertyOptional({ example: 'starter' })
  @IsOptional()
  @IsString()
  status?: string;

  @ApiPropertyOptional({ example: 7.8 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(10)
  rating?: number;

  @ApiPropertyOptional({ type: OpponentPlayerStatsDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => OpponentPlayerStatsDto)
  stats?: OpponentPlayerStatsDto;
}

export class AnalyzeOpponentDto {
  @ApiPropertyOptional({ example: '2026-2027' })
  @IsOptional()
  @IsString()
  season?: string;

  @ApiPropertyOptional({ example: 'high pressing' })
  @IsOptional()
  @IsString()
  opponentStyle?: string;

  @ApiPropertyOptional({ example: 'Wydad AC' })
  @IsOptional()
  @IsString()
  opponentTeamName?: string;

  @ApiPropertyOptional({ example: '4-3-3' })
  @IsOptional()
  @IsString()
  preferredFormation?: string;

  @ApiPropertyOptional({
    type: [String],
    example: ['Transitions rapides', 'Pressing apres perte', 'Jeu aerien']
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  strengths?: string[];

  @ApiPropertyOptional({
    type: [String],
    example: ['Espace derriere les lateraux', 'Faiblesse sur CPA defensifs']
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  weaknesses?: string[];

  @ApiPropertyOptional({
    type: [OpponentPlayerDto],
    description: 'Effectif adverse reel avec stats individuelles par joueur.'
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OpponentPlayerDto)
  opponentSquad?: OpponentPlayerDto[];
}
