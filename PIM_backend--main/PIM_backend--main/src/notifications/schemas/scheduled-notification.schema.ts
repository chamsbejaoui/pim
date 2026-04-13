import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import { NotificationType } from '../../common/enums/notification-type.enum';

export type ScheduledNotificationDocument = HydratedDocument<ScheduledNotification>;

@Schema({ collection: 'scheduled_notifications', timestamps: true })
export class ScheduledNotification {
  @Prop({ type: Types.ObjectId, ref: 'Club', required: true, index: true })
  clubId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  createdByUserId: Types.ObjectId;

  @Prop({ type: String, enum: NotificationType, required: true, index: true })
  type: NotificationType;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  body: string;

  @Prop({ type: [Types.ObjectId], default: [] })
  targetUserIds: Types.ObjectId[];

  @Prop({ type: Object, default: {} })
  data: Record<string, unknown>;

  @Prop({ required: true, index: true })
  scheduleAt: Date;

  @Prop({ type: Date, default: null, index: true })
  sentAt?: Date | null;
}

export const ScheduledNotificationSchema = SchemaFactory.createForClass(ScheduledNotification);

ScheduledNotificationSchema.index({ scheduleAt: 1, sentAt: 1 });
ScheduledNotificationSchema.index({ clubId: 1, scheduleAt: 1, sentAt: 1 });
