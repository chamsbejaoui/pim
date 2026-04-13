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
import { ROLE_PERMISSIONS } from '../common/constants/role-permissions.constant';
import { Permission } from '../common/enums/permission.enum';
import { Role } from '../common/enums/role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { NotificationStatus } from '../common/enums/notification-status.enum';
import { NotificationType } from '../common/enums/notification-type.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { User, UserDocument } from '../users/schemas/user.schema';
import { RealtimeService } from '../realtime/realtime.service';
import {
  EmergencyNotificationDto,
  ListNotificationsDto,
  MarkNotificationsReadDto,
  MedicalAlertDto,
  TrainingReminderDto
} from './dto/notifications.dto';
import { Notification, NotificationDocument } from './schemas/notification.schema';
import {
  ScheduledNotification,
  ScheduledNotificationDocument
} from './schemas/scheduled-notification.schema';
import { calculateNotificationExpiry } from './utils/retention.util';

interface CreateNotificationsInput {
  clubId: string;
  recipientUserIds: string[];
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, unknown>;
}

@Injectable()
export class NotificationsService {
  constructor(
    @InjectModel(Notification.name)
    private readonly notificationModel: Model<NotificationDocument>,
    @InjectModel(ScheduledNotification.name)
    private readonly scheduledNotificationModel: Model<ScheduledNotificationDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    private readonly realtimeService: RealtimeService
  ) {}

  streamForUser(actor: AuthUser): Observable<MessageEvent> {
    const clubId = this.resolveClubId(actor);
    return this.realtimeService.streamForUser('notification', clubId, actor.sub);
  }

  async listForActor(actor: AuthUser, query: ListNotificationsDto) {
    const clubId = this.resolveClubId(actor);
    const filter: FilterQuery<NotificationDocument> = {
      clubId: new Types.ObjectId(clubId),
      recipientUserId: new Types.ObjectId(actor.sub),
      deletedAt: null
    };

    if (query.unreadOnly) {
      filter.status = NotificationStatus.UNREAD;
    }

    if (query.type) {
      filter.type = query.type;
    }

    const limit = Math.min(Math.max(Number(query.limit ?? 60), 1), 200);
    const rows = await this.notificationModel.find(filter).sort({ createdAt: -1 }).limit(limit).lean();

    const canReadMedicalDetails = this.hasPermission(
      actor.role,
      Permission.MEDICAL_ALERT_CONFIDENTIAL_READ
    );

    return rows.map((row) => {
      if (
        row.type === NotificationType.MEDICAL_ALERT &&
        row.data?.confidential === true &&
        !canReadMedicalDetails
      ) {
        return {
          ...row,
          body: 'Confidential medical alert',
          data: {
            ...row.data,
            confidential: true,
            hidden: true
          }
        };
      }

      return row;
    });
  }

  async markReadMany(actor: AuthUser, dto: MarkNotificationsReadDto) {
    const clubId = this.resolveClubId(actor);
    const now = new Date();

    const objectIds = dto.notificationIds.map((id) => new Types.ObjectId(id));
    const result = await this.notificationModel.updateMany(
      {
        _id: { $in: objectIds },
        clubId: new Types.ObjectId(clubId),
        recipientUserId: new Types.ObjectId(actor.sub),
        deletedAt: null,
        status: NotificationStatus.UNREAD
      },
      {
        $set: {
          status: NotificationStatus.READ,
          readAt: now,
          expiresAt: calculateNotificationExpiry(now)
        }
      }
    );

    return { updated: result.modifiedCount };
  }

  async markReadOne(actor: AuthUser, notificationId: string) {
    return this.markReadMany(actor, { notificationIds: [notificationId] });
  }

  async deleteOne(actor: AuthUser, notificationId: string) {
    const clubId = this.resolveClubId(actor);

    const result = await this.notificationModel.updateOne(
      {
        _id: new Types.ObjectId(notificationId),
        clubId: new Types.ObjectId(clubId),
        recipientUserId: new Types.ObjectId(actor.sub),
        deletedAt: null
      },
      {
        $set: { deletedAt: new Date() }
      }
    );

    if (result.modifiedCount === 0) {
      throw new NotFoundException('Notification not found');
    }

    return { success: true };
  }

  async createChatMessageNotifications(params: {
    clubId: string;
    senderUserId: string;
    senderName: string;
    conversationId: string;
    messageId: string;
    preview: string;
    recipientUserIds: string[];
  }) {
    return this.createNotifications({
      clubId: params.clubId,
      recipientUserIds: params.recipientUserIds,
      type: NotificationType.CHAT_MESSAGE,
      title: params.senderName,
      body: params.preview,
      data: {
        conversationId: params.conversationId,
        messageId: params.messageId,
        senderUserId: params.senderUserId
      }
    });
  }

  async createAnnouncements(params: {
    clubId: string;
    senderUserId: string;
    title: string;
    body: string;
    conversationId: string;
    messageId: string;
    recipientUserIds: string[];
  }) {
    return this.createNotifications({
      clubId: params.clubId,
      recipientUserIds: params.recipientUserIds,
      type: NotificationType.ANNOUNCEMENT,
      title: params.title,
      body: params.body,
      data: {
        conversationId: params.conversationId,
        messageId: params.messageId,
        senderUserId: params.senderUserId
      }
    });
  }

  async createEmergency(actor: AuthUser, dto: EmergencyNotificationDto) {
    const clubId = this.resolveClubId(actor);
    const recipients = await this.resolveTargetUsers(clubId, {
      targetUserIds: dto.targetUserIds,
      targetRoles: dto.targetRoles,
      excludeUserId: actor.sub
    });

    if (recipients.length === 0) {
      throw new BadRequestException('No recipients found in this club');
    }

    await this.createNotifications({
      clubId,
      recipientUserIds: recipients,
      type: NotificationType.EMERGENCY,
      title: dto.title,
      body: dto.body,
      data: {
        severity: dto.severity ?? 'HIGH',
        actorUserId: actor.sub,
        priority: 'HIGH'
      }
    });

    return { success: true, recipients: recipients.length };
  }

  async createMedicalAlert(actor: AuthUser, dto: MedicalAlertDto) {
    const clubId = this.resolveClubId(actor);

    const playerIds = await this.resolveTargetUsers(clubId, {
      targetUserIds: dto.targetPlayerIds,
      targetRoles: [Role.JOUEUR],
      strictByIds: true
    });

    if (playerIds.length === 0) {
      throw new BadRequestException('No valid player targets found in this club');
    }

    const extraRoles: Role[] = [];
    if (dto.includeCoaches) {
      extraRoles.push(Role.STAFF_TECHNIQUE);
    }
    if (dto.includeResponsables) {
      extraRoles.push(Role.CLUB_RESPONSABLE);
    }

    const extraIds =
      extraRoles.length > 0
        ? await this.resolveTargetUsers(clubId, {
            targetRoles: extraRoles,
            excludeUserId: undefined
          })
        : [];

    const recipients = Array.from(new Set([...playerIds, ...extraIds]));

    await this.createNotifications({
      clubId,
      recipientUserIds: recipients,
      type: NotificationType.MEDICAL_ALERT,
      title: dto.title,
      body: dto.body,
      data: {
        severity: dto.severity ?? 'MEDIUM',
        actorUserId: actor.sub,
        confidential: dto.confidential !== false
      }
    });

    return { success: true, recipients: recipients.length };
  }

  async scheduleTrainingReminder(actor: AuthUser, dto: TrainingReminderDto) {
    const clubId = this.resolveClubId(actor);
    const scheduleAt = new Date(dto.scheduleAt);
    if (Number.isNaN(scheduleAt.getTime())) {
      throw new BadRequestException('Invalid scheduleAt');
    }

    if (scheduleAt.getTime() <= Date.now()) {
      throw new BadRequestException('scheduleAt must be in the future');
    }

    const recipients = await this.resolveTargetUsers(clubId, {
      targetUserIds: dto.targetUserIds,
      targetRoles: dto.targetRoles,
      excludeUserId: undefined
    });

    if (recipients.length === 0) {
      throw new BadRequestException('No recipients found in this club');
    }

    const scheduled = await this.scheduledNotificationModel.create({
      clubId: new Types.ObjectId(clubId),
      createdByUserId: new Types.ObjectId(actor.sub),
      type: NotificationType.TRAINING_REMINDER,
      title: dto.title,
      body: dto.body,
      targetUserIds: recipients.map((id) => new Types.ObjectId(id)),
      scheduleAt,
      data: {
        trainingId: dto.trainingId ?? null,
        actorUserId: actor.sub
      }
    });

    return {
      scheduledId: scheduled.id,
      recipients: recipients.length,
      scheduleAt
    };
  }

  async dispatchDueTrainingReminders(now = new Date()) {
    const due = await this.scheduledNotificationModel
      .find({
        sentAt: null,
        scheduleAt: { $lte: now }
      })
      .limit(200);

    if (due.length === 0) {
      return { sent: 0 };
    }

    let sentCount = 0;
    for (const item of due) {
      const recipients = item.targetUserIds.map((id) => String(id));
      await this.createNotifications({
        clubId: String(item.clubId),
        recipientUserIds: recipients,
        type: NotificationType.TRAINING_REMINDER,
        title: item.title,
        body: item.body,
        data: {
          ...item.data,
          scheduledNotificationId: item.id,
          scheduleAt: item.scheduleAt.toISOString()
        }
      });

      item.sentAt = now;
      await item.save();
      sentCount += recipients.length;
    }

    return { sent: sentCount };
  }

  async cleanupExpiredNotifications(now = new Date()) {
    const result = await this.notificationModel.deleteMany({
      $or: [
        {
          expiresAt: { $ne: null, $lte: now }
        },
        {
          deletedAt: { $ne: null }
        }
      ]
    });

    return { deleted: result.deletedCount ?? 0 };
  }

  private async createNotifications(input: CreateNotificationsInput) {
    const uniqueRecipientIds = this.normalizeIds(input.recipientUserIds);
    if (uniqueRecipientIds.length === 0) {
      return [];
    }

    const documents = await this.notificationModel.insertMany(
      uniqueRecipientIds.map((recipientUserId) => ({
        clubId: new Types.ObjectId(input.clubId),
        recipientUserId: new Types.ObjectId(recipientUserId),
        type: input.type,
        title: input.title,
        body: input.body,
        data: input.data ?? {},
        status: NotificationStatus.UNREAD,
        deletedAt: null,
        expiresAt: null,
        readAt: null
      }))
    );

    for (const doc of documents) {
      this.realtimeService.emit({
        channel: 'notification',
        eventType: 'notification.created',
        clubId: input.clubId,
        recipientUserIds: [String(doc.recipientUserId)],
        payload: {
          notificationId: doc.id,
          type: doc.type,
          title: doc.title,
          body: doc.body,
          data: doc.data,
          createdAt: doc.createdAt
        }
      });
    }

    return documents;
  }

  private async resolveTargetUsers(
    clubId: string,
    options: {
      targetUserIds?: string[];
      targetRoles?: Role[];
      excludeUserId?: string;
      strictByIds?: boolean;
    }
  ): Promise<string[]> {
    const query: FilterQuery<UserDocument> = {
      clubId: new Types.ObjectId(clubId),
      status: UserStatus.ACTIVE
    };

    if (options.targetUserIds && options.targetUserIds.length > 0) {
      query._id = { $in: this.normalizeIds(options.targetUserIds).map((id) => new Types.ObjectId(id)) };
    }

    if (options.targetRoles && options.targetRoles.length > 0) {
      query.role = { $in: options.targetRoles };
    }

    if (options.excludeUserId) {
      query._id = {
        ...(query._id as Record<string, unknown>),
        $ne: new Types.ObjectId(options.excludeUserId)
      };
    }

    const users = await this.userModel.find(query).select('_id').lean();
    const foundIds = users.map((user) => String(user._id));

    if (options.strictByIds && options.targetUserIds) {
      const expected = this.normalizeIds(options.targetUserIds);
      if (foundIds.length !== expected.length) {
        throw new ForbiddenException('Some targets are outside your club scope or inactive');
      }
    }

    return foundIds;
  }

  private normalizeIds(ids: string[]): string[] {
    return Array.from(new Set(ids.filter(Boolean).map((id) => id.trim())));
  }

  private resolveClubId(actor: AuthUser): string {
    if (!actor.clubId || actor.role === Role.ADMIN) {
      throw new ForbiddenException('Club-scoped access is required');
    }

    return actor.clubId;
  }

  private hasPermission(role: Role, permission: Permission): boolean {
    return (ROLE_PERMISSIONS[role] || []).includes(permission);
  }
}
