import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type AuditLogDocument = HydratedDocument<AuditLog>;

@Schema({ collection: 'audit_logs', timestamps: { createdAt: true, updatedAt: false } })
export class AuditLog {
  @Prop({ type: Types.ObjectId, ref: 'Club', required: true, index: true })
  clubId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  actorUserId: Types.ObjectId;

  @Prop({ required: true, index: true })
  actionType: string;

  @Prop({ required: true, index: true })
  entityType: string;

  @Prop({ required: true, index: true })
  entityId: string;

  @Prop({ type: Object, default: null })
  before: Record<string, unknown> | null;

  @Prop({ type: Object, default: null })
  after: Record<string, unknown> | null;

  @Prop({ type: Object, default: null })
  metadata: Record<string, unknown> | null;

  createdAt: Date;
}

export const AuditLogSchema = SchemaFactory.createForClass(AuditLog);

AuditLogSchema.index({ clubId: 1, createdAt: -1 });
AuditLogSchema.index({ clubId: 1, actionType: 1, createdAt: -1 });
