import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { ApiProperty } from '@nestjs/swagger';

export type PlayerDocument = Player & Document;

@Schema({ timestamps: true })
export class Player {
    @ApiProperty({ example: 'Kylian Mbappé', description: 'Player name' })
    @Prop({ required: true })
    name: string;

    @ApiProperty({ example: 85.5, description: 'Speed score (0-100)' })
    @Prop({ required: true })
    speed: number;

    @ApiProperty({ example: 78.0, description: 'Endurance score (0-100)' })
    @Prop({ required: true })
    endurance: number;

    @ApiProperty({ example: 9.2, description: 'Distance covered (km)' })
    @Prop({ required: true })
    distance: number;

    @ApiProperty({ example: 42, description: 'Number of successful dribbles' })
    @Prop({ required: true })
    dribbles: number;

    @ApiProperty({ example: 5, description: 'Number of shots on target' })
    @Prop({ required: true })
    shots: number;

    @ApiProperty({ example: 1, description: 'Number of injuries' })
    @Prop({ required: true })
    injuries: number;

    @ApiProperty({ example: 72.0, description: 'Average heart rate (bpm)' })
    @Prop({ required: true })
    heart_rate: number;

    @ApiProperty({
        example: 1,
        description: 'Label: 1 = recruited, 0 = not recruited (optional)',
        required: false,
    })
    @Prop({ default: null })
    label: number;

    @ApiProperty({
        example: 'active',
        description: 'Player status: active or archived',
        required: false,
    })
    @Prop({ default: 'active' })
    status: string;
}

export const PlayerSchema = SchemaFactory.createForClass(Player);
