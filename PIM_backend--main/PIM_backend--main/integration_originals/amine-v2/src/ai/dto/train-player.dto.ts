import { ApiProperty } from '@nestjs/swagger';
import {
    IsInt,
    IsOptional,
    Min,
    Max,
} from 'class-validator';
import { BasePlayerFeaturesDto } from './base-player-features.dto';

export class TrainPlayerDto extends BasePlayerFeaturesDto {

    @ApiProperty({
        example: 1,
        description: 'Label: 1 = recruited, 0 = not recruited',
        required: false,
    })
    @IsOptional()
    @IsInt()
    @Min(0)
    @Max(1)
    label?: number;
}
