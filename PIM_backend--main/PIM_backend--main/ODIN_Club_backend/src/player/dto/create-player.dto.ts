import { ApiProperty } from '@nestjs/swagger';
import {
    IsString,
    IsNumber,
    IsInt,
    IsOptional,
    IsIn,
    Min,
    Max,
} from 'class-validator';

export class CreatePlayerDto {
    @ApiProperty({ example: 'Kylian Mbappé' })
    @IsString()
    name: string;

    @ApiProperty({ example: 85.5 })
    @IsNumber()
    @Min(0)
    @Max(100)
    speed: number;

    @ApiProperty({ example: 78.0 })
    @IsNumber()
    @Min(0)
    @Max(100)
    endurance: number;

    @ApiProperty({ example: 9.2 })
    @IsNumber()
    @Min(0)
    distance: number;

    @ApiProperty({ example: 42 })
    @IsNumber()
    @Min(0)
    dribbles: number;

    @ApiProperty({ example: 5 })
    @IsNumber()
    @Min(0)
    shots: number;

    @ApiProperty({ example: 1 })
    @IsInt()
    @Min(0)
    injuries: number;

    @ApiProperty({ example: 72.0 })
    @IsNumber()
    @Min(0)
    heart_rate: number;

    @ApiProperty({ example: 1, required: false, description: '1 = recruited, 0 = not recruited' })
    @IsOptional()
    @IsInt()
    @Min(0)
    @Max(1)
    label?: number;

    @ApiProperty({ example: 'active', required: false, description: 'Player status: active or archived' })
    @IsOptional()
    @IsString()
    @IsIn(['active', 'archived'])
    status?: string;
}
