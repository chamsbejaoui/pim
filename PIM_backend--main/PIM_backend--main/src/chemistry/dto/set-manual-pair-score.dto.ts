import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsMongoId, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class SetManualPairScoreDto {
  @ApiProperty({ example: '2026-2027' })
  @IsString()
  season: string;

  @ApiProperty({ example: '65d31f4b4ec6f6fcb18d6a11' })
  @IsMongoId()
  playerAId: string;

  @ApiProperty({ example: '65d31f4b4ec6f6fcb18d6a12' })
  @IsMongoId()
  playerBId: string;

  @ApiProperty({ example: 7.8, minimum: 0, maximum: 10 })
  @IsNumber()
  @Min(0)
  @Max(10)
  manualScore: number;

  @ApiPropertyOptional({ example: 'Head Coach' })
  @IsOptional()
  @IsString()
  manualScoreBy?: string;

  @ApiPropertyOptional({ example: 'Override after tactical meeting review.' })
  @IsOptional()
  @IsString()
  manualScoreReason?: string;
}
