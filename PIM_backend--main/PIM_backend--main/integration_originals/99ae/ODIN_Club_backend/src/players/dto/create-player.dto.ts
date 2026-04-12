import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsDateString,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min
} from 'class-validator';

export class CreatePlayerDto {
  @ApiPropertyOptional({ example: 'api-football' })
  @IsOptional()
  @IsString()
  providerName?: string;

  @ApiPropertyOptional({ example: '12345' })
  @IsOptional()
  @IsString()
  providerPlayerId?: string;

  @ApiPropertyOptional({ example: 'userId_val' })
  @IsOptional()
  @IsString()
  userId?: string;

  @ApiPropertyOptional({ example: 'Kylian Mbappé' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: 'Kylian' })
  @IsOptional()
  @IsString()
  firstName?: string;

  @ApiPropertyOptional({ example: 'Mbappé' })
  @IsOptional()
  @IsString()
  lastName?: string;

  @ApiPropertyOptional({ example: 24 })
  @IsOptional()
  @IsInt()
  age?: number;

  @ApiPropertyOptional({ example: 'Attaquant' })
  @IsOptional()
  @IsString()
  position?: string;

  @ApiPropertyOptional({ example: '1999-12-20' })
  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @ApiPropertyOptional({ example: 'Right' })
  @IsOptional()
  @IsString()
  strongFoot?: string;

  @ApiPropertyOptional({ example: 10 })
  @IsOptional()
  @IsInt()
  jerseyNumber?: number;

  @ApiPropertyOptional({ example: 178 })
  @IsOptional()
  @IsNumber()
  height?: number;

  @ApiPropertyOptional({ example: 73 })
  @IsOptional()
  @IsNumber()
  weight?: number;

  @ApiPropertyOptional({ example: 'https://...' })
  @IsOptional()
  @IsString()
  photo?: string;

  @ApiPropertyOptional({ example: 'France' })
  @IsOptional()
  @IsString()
  nationality?: string;

  @ApiPropertyOptional({ example: 85.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  speed?: number;

  @ApiPropertyOptional({ example: 78.0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  endurance?: number;

  @ApiPropertyOptional({ example: 9.2 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  distance?: number;

  @ApiPropertyOptional({ example: 42 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  dribbles?: number;

  @ApiPropertyOptional({ example: 5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  shots?: number;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @IsInt()
  @Min(0)
  injuries?: number;

  @ApiPropertyOptional({ example: 72.0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  heart_rate?: number;

  @ApiPropertyOptional({ example: 1, description: '1 = recruited, 0 = not recruited' })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(1)
  label?: number;

  @ApiPropertyOptional({ example: 'active', description: 'active or archived' })
  @IsOptional()
  @IsString()
  status?: string;

  @ApiPropertyOptional({ example: 75 })
  @IsOptional()
  @IsNumber()
  baseFitness?: number;

  @ApiPropertyOptional({ example: 0 })
  @IsOptional()
  @IsInt()
  injuryHistory?: number;

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @IsBoolean()
  isInjured?: boolean;

  @ApiPropertyOptional({ example: 'Hamstring' })
  @IsOptional()
  @IsString()
  lastInjuryType?: string;

  @ApiPropertyOptional({ example: 14 })
  @IsOptional()
  @IsInt()
  lastRecoveryDays?: number;

  @ApiPropertyOptional({ example: 'Mild' })
  @IsOptional()
  @IsString()
  lastSeverity?: string;

  @ApiPropertyOptional({ example: 0.2 })
  @IsOptional()
  @IsNumber()
  lastInjuryProbability?: number;
}
