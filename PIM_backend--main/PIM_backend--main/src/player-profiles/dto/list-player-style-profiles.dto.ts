import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class ListPlayerStyleProfilesDto {
  @ApiPropertyOptional({ example: '2026-2027' })
  @IsOptional()
  @IsString()
  season?: string;

  @ApiPropertyOptional({ example: 120, minimum: 1, maximum: 500, default: 120 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(500)
  limit?: number;
}
