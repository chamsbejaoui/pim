import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsMongoId, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class RatePairDto {
  @ApiProperty({ example: '2026-2027' })
  @IsString()
  season: string;

  @ApiProperty({ example: '65d31f4b4ec6f6fcb18d6a11' })
  @IsMongoId()
  playerAId: string;

  @ApiProperty({ example: '65d31f4b4ec6f6fcb18d6a12' })
  @IsMongoId()
  playerBId: string;

  @ApiProperty({ example: 8.5, minimum: 0, maximum: 10 })
  @IsNumber()
  @Min(0)
  @Max(10)
  rating: number;

  @ApiPropertyOptional({ example: 'Coach principal' })
  @IsOptional()
  @IsString()
  observedBy?: string;

  @ApiPropertyOptional({ example: 'left-flank' })
  @IsOptional()
  @IsString()
  tacticalZone?: string;

  @ApiPropertyOptional({ example: 'Bonne coordination sur les combinaisons courtes.' })
  @IsOptional()
  @IsString()
  notes?: string;
}
