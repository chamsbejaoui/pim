import { ApiProperty } from '@nestjs/swagger';
import {
    IsMongoId,
    IsOptional,
    IsString,
    IsDateString,
    IsNumber,
    IsInt,
    Min,
    Max,
} from 'class-validator';

export class BasePlayerFeaturesDto {
    @ApiProperty({ required: false, description: 'Linked User ID (if player is mapped to a user account)' })
    @IsOptional()
    @IsMongoId()
    userId?: string;

    @ApiProperty({ example: 'Kylian' })
    @IsString()
    firstName: string;

    @ApiProperty({ example: 'Mbappé' })
    @IsString()
    lastName: string;

    @ApiProperty({ required: false, example: '1998-12-20', description: 'Date of birth (ISO format)' })
    @IsOptional()
    @IsDateString()
    dateOfBirth?: string;

    @ApiProperty({ required: false, example: 'Forward' })
    @IsOptional()
    @IsString()
    position?: string;

    @ApiProperty({ required: false, example: 'Right' })
    @IsOptional()
    @IsString()
    strongFoot?: string;

    @ApiProperty({ required: false, example: 7 })
    @IsOptional()
    @IsInt()
    @Min(0)
    jerseyNumber?: number;

    @ApiProperty({ required: false, example: 178, description: 'Height in cm' })
    @IsOptional()
    @IsNumber()
    @Min(0)
    height?: number;

    @ApiProperty({ required: false, example: 73, description: 'Weight in kg' })
    @IsOptional()
    @IsNumber()
    @Min(0)
    weight?: number;

    @ApiProperty({ required: false, example: 'https://cdn.example.com/player.jpg' })
    @IsOptional()
    @IsString()
    photo?: string;

    @ApiProperty({ required: false, example: 'France' })
    @IsOptional()
    @IsString()
    nationality?: string;

    @ApiProperty({ example: 85.5, description: 'Speed score (0-100)' })
    @IsNumber()
    @Min(0)
    @Max(100)
    speed: number;

    @ApiProperty({ example: 78.0, description: 'Endurance score (0-100)' })
    @IsNumber()
    @Min(0)
    @Max(100)
    endurance: number;

    @ApiProperty({ example: 9.2, description: 'Distance covered (km)' })
    @IsNumber()
    @Min(0)
    distance: number;

    @ApiProperty({ example: 42, description: 'Number of successful dribbles' })
    @IsNumber()
    @Min(0)
    dribbles: number;

    @ApiProperty({ example: 5, description: 'Number of shots on target' })
    @IsNumber()
    @Min(0)
    shots: number;

    @ApiProperty({ example: 1, description: 'Number of injuries' })
    @IsInt()
    @Min(0)
    injuries: number;

    @ApiProperty({ example: 72.0, description: 'Average heart rate (bpm)' })
    @IsNumber()
    @Min(0)
    heart_rate: number;

    @ApiProperty({ required: false, example: 23, description: 'Age of the player' })
    @IsOptional()
    @IsInt()
    @Min(0)
    age?: number;

    @ApiProperty({ required: false, example: 'ODIN Club' })
    @IsOptional()
    @IsString()
    club?: string;

    @ApiProperty({ required: false, example: 1, description: 'Training label: 1=recruited, 0=not recruited' })
    @IsOptional()
    @IsInt()
    @Min(0)
    @Max(1)
    label?: number;
}