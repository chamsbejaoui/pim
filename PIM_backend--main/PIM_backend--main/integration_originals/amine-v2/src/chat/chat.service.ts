import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { MessageEvent } from '@nestjs/common';
import { FilterQuery, Model, Types } from 'mongoose';
import { Observable } from 'rxjs';
import { NotificationType } from '../common/enums/notification-type.enum';
import { ConversationType } from '../common/enums/conversation-type.enum';
import { MessageContentType } from '../common/enums/message-content-type.enum';
import { Role } from '../common/enums/role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { RealtimeService } from '../realtime/realtime.service';
import { User, UserDocument } from '../users/schemas/user.schema';
import { NotificationsService } from '../notifications/notifications.service';
import {
  CreateAnnouncementDto,
  CreateDirectConversationDto,
  CreateGroupConversationDto,
  DeleteMessageDto,
  ListChatUsersDto,
  ListConversationsDto,
  ListMessagesDto,
  SendMessageDto
} from './dto/chat.dto';
import {
  Conversation,
  ConversationDocument,
  ConversationParticipant
} from './schemas/conversation.schema';
import { Message, MessageDocument } from './schemas/message.schema';
import { canDeleteMessageForEveryone } from './utils/delete-scope.util';

interface ConversationParticipantLean {
  userId: Types.ObjectId;
  role: Role;
  lastReadAt?: Date | null;
}

interface ConversationLean {
  _id: Types.ObjectId;
  type: ConversationType;
  participants: ConversationParticipantLean[];
  title?: string | null;
  lastMessagePreview: string;
  lastMessageAt?: Date | null;
}

interface UserProfileLean {
  _id: Types.ObjectId;
  firstName: string;
  lastName: string;
  role: Role;
  photoUrl?: string | null;
}

interface ParticipantView {
  userId: string;
  firstName: string;
  lastName: string;
  role: Role;
  photoUrl: string | null;
  lastReadAt: Date | null;
}

@Injectable()
export class ChatService {
  constructor(
    @InjectModel(Conversation.name)
    private readonly conversationModel: Model<ConversationDocument>,
    @InjectModel(Message.name)
    private readonly messageModel: Model<MessageDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    private readonly notificationsService: NotificationsService,
    private readonly realtimeService: RealtimeService
  ) {}

  streamForActor(actor: AuthUser): Observable<MessageEvent> {
    const clubId = this.resolveClubId(actor);
    return this.realtimeService.streamForUser('chat', clubId, actor.sub);
  }

  async listSameClubUsers(actor: AuthUser, query: ListChatUsersDto) {
    const clubId = this.resolveClubId(actor);
    const limit = Math.min(Math.max(Number(query.limit ?? 50), 1), 200);

    const filter: FilterQuery<UserDocument> = {
      clubId: new Types.ObjectId(clubId),
      status: UserStatus.ACTIVE,
      _id: { $ne: new Types.ObjectId(actor.sub) }
    };

    if (query.search) {
      const regex = new RegExp(query.search.trim(), 'i');
      filter.$or = [
        { firstName: regex },
        { lastName: regex },
        { email: regex },
        { phone: regex }
      ];
    }

    return this.userModel
      .find(filter)
      .select('_id firstName lastName email phone role photoUrl clubId')
      .sort({ firstName: 1, lastName: 1 })
      .limit(limit)
      .lean();
  }

  async listConversations(actor: AuthUser, query: ListConversationsDto) {
    const clubId = this.resolveClubId(actor);
    const page = Math.max(Number(query.page ?? 1), 1);
    const limit = Math.min(Math.max(Number(query.limit ?? 30), 1), 100);

    const filter: FilterQuery<ConversationDocument> = {
      clubId: new Types.ObjectId(clubId),
      'participants.userId': new Types.ObjectId(actor.sub),
      isArchived: { $ne: true }
    };

    if (query.search) {
      const regex = new RegExp(query.search.trim(), 'i');
      filter.$or = [{ title: regex }, { lastMessagePreview: regex }];
    }

    const conversations = await this.conversationModel
      .find(filter)
      .sort({ lastMessageAt: -1, createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean<ConversationLean[]>();

    const allParticipantIds = new Set<string>();
    for (const conv of conversations) {
      for (const participant of conv.participants || []) {
        allParticipantIds.add(String(participant.userId));
      }
    }

    const users = await this.userModel
      .find({ _id: { $in: Array.from(allParticipantIds).map((id) => new Types.ObjectId(id)) } })
      .select('_id firstName lastName role photoUrl')
      .lean<UserProfileLean[]>();

    const userMap = new Map<string, UserProfileLean>();
    for (const user of users) {
      userMap.set(String(user._id), user);
    }

    const actorObjectId = new Types.ObjectId(actor.sub);

    const items = await Promise.all(
      conversations.map(async (conversation) => {
        const participantRow = (conversation.participants || []).find(
          (participant) => String(participant.userId) === actor.sub
        );

        const unreadFilter: FilterQuery<MessageDocument> = {
          clubId: new Types.ObjectId(clubId),
          conversationId: new Types.ObjectId(String(conversation._id)),
          senderId: { $ne: actorObjectId },
          deletedAt: null,
          deletedFor: { $ne: actorObjectId }
        };

        if (participantRow?.lastReadAt) {
          unreadFilter.createdAt = { $gt: new Date(participantRow.lastReadAt) };
        }

        const unreadCount = await this.messageModel.countDocuments(unreadFilter);

        const participantProfiles = (conversation.participants || [])
          .map<ParticipantView | null>((participant) => {
            const profile = userMap.get(String(participant.userId));
            if (!profile) {
              return null;
            }

            return {
              userId: String(profile._id),
              firstName: profile.firstName,
              lastName: profile.lastName,
              role: profile.role,
              photoUrl: profile.photoUrl ?? null,
              lastReadAt: participant.lastReadAt ?? null
            };
          })
          .filter((participant): participant is ParticipantView => participant !== null);

        const directOther =
          conversation.type === ConversationType.DIRECT
            ? participantProfiles.find((participant) => participant.userId !== actor.sub)
            : null;

        return {
          ...conversation,
          participants: participantProfiles,
          displayTitle:
            conversation.type === ConversationType.DIRECT && directOther
              ? `${directOther.firstName} ${directOther.lastName}`.trim()
              : conversation.title || 'Conversation',
          unreadCount
        };
      })
    );

    return {
      page,
      limit,
      items
    };
  }

  async createDirectConversation(actor: AuthUser, dto: CreateDirectConversationDto) {
    const clubId = this.resolveClubId(actor);
    if (dto.targetUserId === actor.sub) {
      throw new BadRequestException('Cannot create a direct conversation with yourself');
    }

    const target = await this.userModel.findOne({
      _id: new Types.ObjectId(dto.targetUserId),
      clubId: new Types.ObjectId(clubId),
      status: UserStatus.ACTIVE
    });
    if (!target) {
      throw new ForbiddenException('Target user not found in your club');
    }

    const actorRole = actor.role;
    const existing = await this.conversationModel.findOne({
      clubId: new Types.ObjectId(clubId),
      type: ConversationType.DIRECT,
      'participants.userId': {
        $all: [new Types.ObjectId(actor.sub), new Types.ObjectId(dto.targetUserId)]
      },
      $expr: {
        $eq: [{ $size: '$participants' }, 2]
      }
    });

    if (existing) {
      return existing;
    }

    const participants: ConversationParticipant[] = [
      {
        userId: new Types.ObjectId(actor.sub),
        role: actorRole,
        lastReadAt: new Date()
      },
      {
        userId: new Types.ObjectId(dto.targetUserId),
        role: target.role,
        lastReadAt: null
      }
    ];

    return this.conversationModel.create({
      clubId: new Types.ObjectId(clubId),
      type: ConversationType.DIRECT,
      participants,
      createdBy: new Types.ObjectId(actor.sub),
      title: null,
      lastMessagePreview: '',
      lastMessageAt: null,
      isArchived: false
    });
  }

  async createGroupConversation(actor: AuthUser, dto: CreateGroupConversationDto) {
    const clubId = this.resolveClubId(actor);
    const uniqueIds = Array.from(new Set([...dto.participantIds, actor.sub]));

    const users = await this.userModel
      .find({
        _id: { $in: uniqueIds.map((id) => new Types.ObjectId(id)) },
        clubId: new Types.ObjectId(clubId),
        status: UserStatus.ACTIVE
      })
      .select('_id role');

    if (users.length !== uniqueIds.length) {
      throw new ForbiddenException('Some participants are outside your club scope or inactive');
    }

    const participants = users.map((user) => ({
      userId: new Types.ObjectId(String(user._id)),
      role: user.role,
      lastReadAt: String(user._id) === actor.sub ? new Date() : null
    }));

    return this.conversationModel.create({
      clubId: new Types.ObjectId(clubId),
      type: ConversationType.GROUP,
      participants,
      title: dto.title,
      createdBy: new Types.ObjectId(actor.sub),
      lastMessagePreview: '',
      lastMessageAt: null,
      isArchived: false
    });
  }

  async listMessages(actor: AuthUser, conversationId: string, query: ListMessagesDto) {
    const clubId = this.resolveClubId(actor);
    const conversation = await this.getConversationForActor(conversationId, actor, clubId);

    const limit = Math.min(Math.max(Number(query.limit ?? 40), 1), 120);
    const actorObjectId = new Types.ObjectId(actor.sub);

    const filter: FilterQuery<MessageDocument> = {
      clubId: new Types.ObjectId(clubId),
      conversationId: new Types.ObjectId(conversationId),
      deletedFor: { $ne: actorObjectId }
    };

    if (query.before) {
      filter.createdAt = { $lt: new Date(query.before) };
    }

    const rows = await this.messageModel.find(filter).sort({ createdAt: -1 }).limit(limit).lean();

    const items = rows
      .reverse()
      .map((row) =>
        row.deletedAt
          ? {
              ...row,
              contentType: MessageContentType.SYSTEM,
              text: 'Message deleted',
              file: null
            }
          : row
      );

    await this.conversationModel.updateOne(
      {
        _id: conversation._id,
        'participants.userId': actorObjectId
      },
      {
        $set: {
          'participants.$.lastReadAt': new Date()
        }
      }
    );

    return {
      items,
      hasMore: rows.length === limit,
      nextBefore: rows.length > 0 ? rows[rows.length - 1].createdAt : null
    };
  }

  async sendMessage(actor: AuthUser, conversationId: string, dto: SendMessageDto) {
    const clubId = this.resolveClubId(actor);
    const conversation = await this.getConversationForActor(conversationId, actor, clubId);

    const text = dto.text?.trim();
    if (!text && !dto.file) {
      throw new BadRequestException('Message must include text or file');
    }

    const message = await this.messageModel.create({
      clubId: new Types.ObjectId(clubId),
      conversationId: new Types.ObjectId(conversationId),
      senderId: new Types.ObjectId(actor.sub),
      senderRole: actor.role,
      contentType: dto.file ? MessageContentType.FILE : MessageContentType.TEXT,
      text: text || null,
      file: dto.file || null,
      deletedFor: [],
      deletedAt: null,
      metadata: dto.metadata || {}
    });

    const preview = dto.file ? `Attachment: ${dto.file.name}` : (text as string);

    await this.conversationModel.updateOne(
      { _id: conversation._id, 'participants.userId': new Types.ObjectId(actor.sub) },
      {
        $set: {
          lastMessageAt: message.createdAt,
          lastMessagePreview: preview,
          'participants.$.lastReadAt': message.createdAt
        }
      }
    );

    const participantIds = (conversation.participants || []).map((participant) => String(participant.userId));
    const recipientUserIds = participantIds.filter((id) => id !== actor.sub);

    const senderProfile = await this.userModel
      .findById(actor.sub)
      .select('firstName lastName')
      .lean();
    const senderName = senderProfile
      ? `${senderProfile.firstName} ${senderProfile.lastName}`.trim()
      : actor.email;

    if (recipientUserIds.length > 0) {
      await this.notificationsService.createChatMessageNotifications({
        clubId,
        senderUserId: actor.sub,
        senderName,
        conversationId,
        messageId: message.id,
        preview,
        recipientUserIds
      });

      this.realtimeService.emit({
        channel: 'chat',
        eventType: 'chat.message.created',
        clubId,
        recipientUserIds,
        payload: {
          conversationId,
          messageId: message.id,
          senderId: actor.sub,
          preview,
          contentType: message.contentType,
          createdAt: message.createdAt
        }
      });
    }

    return message;
  }

  async deleteMessage(actor: AuthUser, messageId: string, dto: DeleteMessageDto) {
    const clubId = this.resolveClubId(actor);
    const message = await this.messageModel.findOne({
      _id: new Types.ObjectId(messageId),
      clubId: new Types.ObjectId(clubId)
    });

    if (!message) {
      throw new NotFoundException('Message not found');
    }

    await this.getConversationForActor(String(message.conversationId), actor, clubId);

    if (dto.scope === 'me') {
      await this.messageModel.updateOne(
        { _id: message._id },
        {
          $addToSet: { deletedFor: new Types.ObjectId(actor.sub) }
        }
      );

      return { success: true, scope: 'me' };
    }

    const canDelete = canDeleteMessageForEveryone({
      actorUserId: actor.sub,
      actorRole: actor.role,
      senderUserId: String(message.senderId)
    });

    if (!canDelete) {
      throw new ForbiddenException('Delete for everyone is not allowed for this user');
    }

    if (message.deletedAt) {
      return { success: true, scope: 'everyone' };
    }

    message.deletedAt = new Date();
    message.contentType = MessageContentType.SYSTEM;
    message.text = 'Message deleted';
    message.file = null;
    message.metadata = {
      ...message.metadata,
      deletedBy: actor.sub
    };
    await message.save();

    await this.refreshConversationPreview(clubId, String(message.conversationId));

    const conversation = await this.conversationModel
      .findById(message.conversationId)
      .select('participants')
      .lean();

    const participants = (conversation?.participants || []) as { userId: Types.ObjectId }[];
    const recipients = participants
      .map((participant) => String(participant.userId))
      .filter((id: string) => id !== actor.sub);

    if (recipients.length > 0) {
      this.realtimeService.emit({
        channel: 'chat',
        eventType: 'chat.message.deleted',
        clubId,
        recipientUserIds: recipients,
        payload: {
          conversationId: String(message.conversationId),
          messageId,
          scope: 'everyone'
        }
      });
    }

    return { success: true, scope: 'everyone' };
  }

  async createAnnouncement(actor: AuthUser, dto: CreateAnnouncementDto) {
    const clubId = this.resolveClubId(actor);

    const recipients = await this.resolveAnnouncementTargets(clubId, actor.sub, dto);
    if (recipients.length === 0) {
      throw new BadRequestException('No announcement recipients found in this club');
    }

    const senderObjectId = new Types.ObjectId(actor.sub);
    const recipientObjectIds = recipients.map((id) => new Types.ObjectId(id));

    const recipientUsers = await this.userModel
      .find({ _id: { $in: recipientObjectIds }, clubId: new Types.ObjectId(clubId) })
      .select('_id role');

    const participants: ConversationParticipant[] = [
      {
        userId: senderObjectId,
        role: actor.role,
        lastReadAt: new Date()
      },
      ...recipientUsers.map((user) => ({
        userId: new Types.ObjectId(String(user._id)),
        role: user.role,
        lastReadAt: null
      }))
    ];

    const conversation = await this.conversationModel.create({
      clubId: new Types.ObjectId(clubId),
      type: ConversationType.ANNOUNCEMENT,
      participants,
      title: dto.title,
      createdBy: senderObjectId,
      lastMessageAt: null,
      lastMessagePreview: '',
      isArchived: false
    });

    const message = await this.messageModel.create({
      clubId: new Types.ObjectId(clubId),
      conversationId: new Types.ObjectId(conversation.id),
      senderId: senderObjectId,
      senderRole: actor.role,
      contentType: MessageContentType.SYSTEM,
      text: dto.text,
      file: null,
      deletedFor: [],
      deletedAt: null,
      metadata: {
        announcement: true
      }
    });

    conversation.lastMessageAt = message.createdAt;
    conversation.lastMessagePreview = dto.text;
    await conversation.save();

    await this.notificationsService.createAnnouncements({
      clubId,
      senderUserId: actor.sub,
      title: dto.title,
      body: dto.text,
      conversationId: conversation.id,
      messageId: message.id,
      recipientUserIds: recipients
    });

    this.realtimeService.emit({
      channel: 'chat',
      eventType: 'chat.announcement.created',
      clubId,
      recipientUserIds: recipients,
      payload: {
        conversationId: conversation.id,
        messageId: message.id,
        title: dto.title,
        text: dto.text,
        type: NotificationType.ANNOUNCEMENT
      }
    });

    return {
      conversation,
      message,
      recipients: recipients.length
    };
  }

  private async resolveAnnouncementTargets(
    clubId: string,
    actorUserId: string,
    dto: CreateAnnouncementDto
  ): Promise<string[]> {
    const query: FilterQuery<UserDocument> = {
      clubId: new Types.ObjectId(clubId),
      status: UserStatus.ACTIVE,
      _id: { $ne: new Types.ObjectId(actorUserId) }
    };

    const normalizedTargetIds = dto.targetUserIds
      ? Array.from(new Set(dto.targetUserIds.map((id) => id.trim())))
      : [];

    if (normalizedTargetIds.length > 0) {
      query._id = {
        $in: normalizedTargetIds.map((id) => new Types.ObjectId(id)),
        $ne: new Types.ObjectId(actorUserId)
      };
    }

    if (dto.targetRoles && dto.targetRoles.length > 0) {
      query.role = { $in: dto.targetRoles };
    }

    const users = await this.userModel.find(query).select('_id').lean();

    if (normalizedTargetIds.length > 0 && users.length !== normalizedTargetIds.length) {
      throw new ForbiddenException('Some target users are outside your club scope');
    }

    return users.map((user) => String(user._id));
  }

  private async refreshConversationPreview(clubId: string, conversationId: string) {
    const latest = await this.messageModel
      .findOne({
        clubId: new Types.ObjectId(clubId),
        conversationId: new Types.ObjectId(conversationId)
      })
      .sort({ createdAt: -1 })
      .lean();

    const preview = latest
      ? latest.deletedAt
        ? 'Message deleted'
        : latest.file
          ? `Attachment: ${latest.file.name}`
          : (latest.text ?? '')
      : '';

    await this.conversationModel.updateOne(
      { _id: new Types.ObjectId(conversationId), clubId: new Types.ObjectId(clubId) },
      {
        $set: {
          lastMessageAt: latest?.createdAt ?? null,
          lastMessagePreview: preview
        }
      }
    );
  }

  private async getConversationForActor(
    conversationId: string,
    actor: AuthUser,
    clubId: string
  ): Promise<ConversationDocument> {
    const conversation = await this.conversationModel.findOne({
      _id: new Types.ObjectId(conversationId),
      clubId: new Types.ObjectId(clubId),
      'participants.userId': new Types.ObjectId(actor.sub)
    });

    if (!conversation) {
      throw new ForbiddenException('Conversation not found in your club scope');
    }

    return conversation;
  }

  private resolveClubId(actor: AuthUser): string {
    if (!actor.clubId || actor.role === Role.ADMIN) {
      throw new ForbiddenException('Club-scoped access is required');
    }

    return actor.clubId;
  }
}
