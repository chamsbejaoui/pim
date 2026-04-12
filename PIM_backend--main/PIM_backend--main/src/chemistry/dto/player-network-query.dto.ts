import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class PlayerNetworkQueryDto {
  @ApiPropertyOptional({ example: '2026-2027' })
  @IsOptional()
  @IsString()
  season?: string;

  @ApiPropertyOptional({ example: false, default: false })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  includeAiInsights?: boolean;
}
