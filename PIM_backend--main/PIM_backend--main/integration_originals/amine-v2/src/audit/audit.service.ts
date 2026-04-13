import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, Types } from 'mongoose';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { Role } from '../common/enums/role.enum';
import { ListAuditDto } from './dto/list-audit.dto';
import { AuditLog, AuditLogDocument } from './schemas/audit-log.schema';

export interface WriteAuditPayload {
  clubId: string;
  actorUserId: string;
  actionType: string;
  entityType: string;
  entityId: string;
  before: unknown | null;
  after: unknown | null;
  metadata?: Record<string, unknown> | null;
}

@Injectable()
export class AuditService {
  constructor(@InjectModel(AuditLog.name) private readonly auditModel: Model<AuditLogDocument>) {}

  async write(payload: WriteAuditPayload) {
    const entry = new this.auditModel({
      ...payload,
      clubId: new Types.ObjectId(payload.clubId),
      actorUserId: new Types.ObjectId(payload.actorUserId),
      metadata: payload.metadata || null
    });

    await entry.save();
    return entry;
  }

  async listForActor(actor: AuthUser, filters: ListAuditDto) {
    const query: FilterQuery<AuditLogDocument> = {};

    if (actor.role !== Role.ADMIN) {
      query.clubId = actor.clubId ? new Types.ObjectId(actor.clubId) : null;
    }

    if (filters.actionType) {
      query.actionType = filters.actionType;
    }
    if (filters.entityType) {
      query.entityType = filters.entityType;
    }
    if (filters.from || filters.to) {
      query.createdAt = {};
      if (filters.from) {
        query.createdAt.$gte = new Date(filters.from);
      }
      if (filters.to) {
        query.createdAt.$lte = new Date(filters.to);
      }
    }

    return this.auditModel.find(query).sort({ createdAt: -1 }).lean();
  }

  async getDailySensitiveSummary(
    actorUserId: string,
    actionType: string,
    from: Date,
    to: Date
  ): Promise<{ count: number; totalAmount: number }> {
    const result = await this.auditModel.aggregate<{
      _id: null;
      count: number;
      totalAmount: number;
    }>([
      {
        $match: {
          actorUserId: new Types.ObjectId(actorUserId),
          actionType,
          createdAt: { $gte: from, $lte: to }
        }
      },
      {
        $group: {
          _id: null,
          count: { $sum: 1 },
          totalAmount: { $sum: { $ifNull: ['$metadata.amount', 0] } }
        }
      }
    ]);

    if (!result[0]) {
      return { count: 0, totalAmount: 0 };
    }

    return { count: result[0].count, totalAmount: result[0].totalAmount || 0 };
  }
}
