import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type EventDocument = Event & Document;

export enum EventType {
    TEST_SESSION = 'test_session',
    MATCH = 'match',
    EVALUATION = 'evaluation',
    DETECTION = 'detection',
    MEDICAL = 'medical',
    RECOVERY = 'recovery',
    AI_ANALYSIS = 'ai_analysis',
}

export enum EventStatus {
    DRAFT = 'draft',
    IN_PROGRESS = 'in_progress',
    COMPLETED = 'completed',
}

@Schema({ timestamps: true })
export class Event {
    @Prop({ required: true })
    title: string;

    @Prop({ type: String, enum: EventType, required: true })
    type: EventType;

    @Prop({ required: true })
    date: Date;

    @Prop()
    endDate?: Date;

    @Prop()
    location?: string;

    @Prop({ type: String, enum: EventStatus, default: EventStatus.DRAFT })
    status: EventStatus;

    @Prop()
    description?: string;

    @Prop({ type: Types.ObjectId, ref: 'User', required: true })
    coachId: Types.ObjectId;

    @Prop({ type: [{ type: Types.ObjectId, ref: 'TestType' }], default: [] })
    testTypes: Types.ObjectId[];
}

export const EventSchema = SchemaFactory.createForClass(Event);
