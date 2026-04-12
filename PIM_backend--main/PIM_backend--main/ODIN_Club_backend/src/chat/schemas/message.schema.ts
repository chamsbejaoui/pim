import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import { MessageContentType } from '../../common/enums/message-content-type.enum';
import { Role } from '../../common/enums/role.enum';

export type MessageDocument = HydratedDocument<Message>;

@Schema({ _id: false })
class MessageFile {
  @Prop({ required: true })
  url: string;

  @Prop({ required: true })
  mimeType: string;

  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  size: number;
}

const MessageFileSchema = SchemaFactory.createForClass(MessageFile);

@Schema({ collection: 'messages', timestamps: { createdAt: true, updatedAt: false } })
export class Message {
  @Prop({ type: Types.ObjectId, ref: 'Club', required: true, index: true })
  clubId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Conversation', required: true, index: true })
  conversationId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  senderId: Types.ObjectId;

  @Prop({ type: String, enum: Role, required: true })
  senderRole: Role;

  @Prop({ type: String, enum: MessageContentType, required: true })
  contentType: MessageContentType;

  @Prop({ type: String, default: null })
  text?: string | null;

  @Prop({ type: MessageFileSchema, default: null })
  file?: MessageFile | null;

  createdAt: Date;

  @Prop({ type: [Types.ObjectId], default: [] })
  deletedFor: Types.ObjectId[];

  @Prop({ type: Date, default: null, index: true })
  deletedAt?: Date | null;

  @Prop({ type: Object, default: {} })
  metadata: Record<string, unknown>;
}

export const MessageSchema = SchemaFactory.createForClass(Message);

MessageSchema.index({ clubId: 1, conversationId: 1, createdAt: -1 });
MessageSchema.index({ conversationId: 1, createdAt: -1 });
