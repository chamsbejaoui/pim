import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type PlayerDocument = Player & Document;

@Schema({ timestamps: true })
export class Player {
    @Prop({ type: Types.ObjectId, ref: 'User', required: false })
    userId?: Types.ObjectId;

    @Prop({ required: true })
    firstName: string;

    @Prop({ required: true })
    lastName: string;

    @Prop({ required: true })
    dateOfBirth: Date;

    @Prop({ required: true })
    position: string;

    @Prop({ required: true }) // 'Right' | 'Left' | 'Both'
    strongFoot: string;

    @Prop()
    jerseyNumber?: number;

    @Prop()
    height?: number; // en cm

    @Prop()
    weight?: number; // en kg

    @Prop()
    photo?: string;

    @Prop()
    nationality?: string;

    // Performance metrics for AI prediction and training
    @Prop({ default: 0, min: 0, max: 100 })
    speed?: number; // Speed score (0-100)

    @Prop({ default: 0, min: 0, max: 100 })
    endurance?: number; // Endurance score (0-100)

    @Prop({ default: 0, min: 0 })
    distance?: number; // Distance covered (km)

    @Prop({ default: 0, min: 0 })
    dribbles?: number; // Number of successful dribbles

    @Prop({ default: 0, min: 0 })
    shots?: number; // Number of shots on target

    @Prop({ default: 0, min: 0 })
    injuries?: number; // Number of injuries

    @Prop({ default: 0, min: 0 })
    heart_rate?: number; // Average heart rate (bpm)

    // AI model label: 1 = recruited candidate, 0 = not recruited (optional)
    @Prop({ default: null })
    label?: number;

    @Prop({
        type: {
            totalEvents: { type: Number, default: 0 },
            averageScore: { type: Number, default: 0 },
            bestScore: { type: Number, default: 0 },
            rank: { type: String, default: 'N/A' },
        },
        default: {},
    })
    statistics: {
        totalEvents: number;
        averageScore: number;
        bestScore: number;
        rank: string;
    };
}

export const PlayerSchema = SchemaFactory.createForClass(Player);
