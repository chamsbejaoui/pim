import { ApiProperty, ApiPropertyOptional, OmitType } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsMongoId,
  IsOptional,
  IsString
} from 'class-validator';

export class CreateSquadDto {
  @ApiProperty({ example: '2026-2027' })
  @IsString()
  season: string;

  @ApiPropertyOptional({ example: 'Squad principal - Saison 2026/2027' })
  @IsOptional()
  @IsString()
  label?: string;

  @ApiProperty({
    type: [String],
    description: 'Les 24 joueurs retenus pour la saison.',
    minItems: 24,
    maxItems: 24
  })
  @IsArray()
  @ArrayMinSize(24)
  @ArrayMaxSize(24)
  @IsMongoId({ each: true })
  playerIds: string[];

  @ApiProperty({
    type: [String],
    description: 'Les 11 titulaires.',
    minItems: 11,
    maxItems: 11
  })
  @IsArray()
  @ArrayMinSize(11)
  @ArrayMaxSize(11)
  @IsMongoId({ each: true })
  starterIds: string[];

  @ApiProperty({
    type: [String],
    description: 'Les 8 remplacants.',
    minItems: 8,
    maxItems: 8
  })
  @IsArray()
  @ArrayMinSize(8)
  @ArrayMaxSize(8)
  @IsMongoId({ each: true })
  benchIds: string[];

  @ApiPropertyOptional({
    type: [String],
    description: 'Optionnel: les reservistes (5). Si omis, calcules automatiquement.',
    minItems: 5,
    maxItems: 5
  })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(5)
  @ArrayMaxSize(5)
  @IsMongoId({ each: true })
  reserveIds?: string[];
}

export class SetSeasonSquadDto extends OmitType(CreateSquadDto, ['season'] as const) {}
