import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import { ConversationType } from '../../common/enums/conversation-type.enum';
import { Role } from '../../common/enums/role.enum';

export type ConversationDocument = HydratedDocument<Conversation>;

@Schema({ _id: false })
export class ConversationParticipant {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ type: String, enum: Role, required: true })
  role: Role;

  @Prop({ type: Date, default: null })
  lastReadAt?: Date | null;
}

const ConversationParticipantSchema = SchemaFactory.createForClass(ConversationParticipant);

@Schema({ collection: 'conversations', timestamps: true })
export class Conversation {
  @Prop({ type: Types.ObjectId, ref: 'Club', required: true, index: true })
  clubId: Types.ObjectId;

  @Prop({ type: String, enum: ConversationType, required: true, index: true })
  type: ConversationType;

  @Prop({ type: [ConversationParticipantSchema], default: [] })
  participants: ConversationParticipant[];

  @Prop()
  title?: string;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  createdBy: Types.ObjectId;

  @Prop({ type: Date, default: null, index: true })
  lastMessageAt?: Date | null;

  @Prop({ default: '' })
  lastMessagePreview: string;

  @Prop({ default: false })
  isArchived?: boolean;
}

export const ConversationSchema = SchemaFactory.createForClass(Conversation);

ConversationSchema.index({ clubId: 1, lastMessageAt: -1 });
ConversationSchema.index({ clubId: 1, 'participants.userId': 1, lastMessageAt: -1 });
