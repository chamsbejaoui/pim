import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, Types } from 'mongoose';
import { AuditService } from '../audit/audit.service';
import { Role } from '../common/enums/role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { ApproveUserDto } from './dto/approve-user.dto';
import { ListUsersDto } from './dto/list-users.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { User, UserDocument } from './schemas/user.schema';

export interface CreateUserPayload {
  clubId?: string | null;
  email: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  phone: string;
  photoUrl?: string;
  role: Role;
  status: UserStatus;
  position?: string;
  jobTitle?: string;
  isEmailVerified?: boolean;
}

@Injectable()
export class UsersService {
  private readonly listProjection = '-passwordHash -__v';

  constructor(
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    private readonly auditService: AuditService
  ) {}

  async findById(id: string) {
    return this.userModel.findById(id);
  }

  async findByEmail(email: string) {
    return this.userModel.findOne({ email: email.toLowerCase() });
  }

  async createUser(payload: CreateUserPayload) {
    const exists = await this.findByEmail(payload.email);
    if (exists) {
      throw new BadRequestException('Email already in use');
    }

    const document = new this.userModel({
      ...payload,
      email: payload.email.toLowerCase(),
      clubId: payload.clubId ? new Types.ObjectId(payload.clubId) : null,
      isEmailVerified: payload.isEmailVerified ?? true
    });
    return document.save();
  }

  async listPendingUsersByClub(clubId: string) {
    return this.userModel
      .find({ clubId: new Types.ObjectId(clubId), status: UserStatus.PENDING_CLUB_APPROVAL })
      .select(this.listProjection)
      .sort({ createdAt: -1 })
      .lean();
  }

  async listPendingUsersForResponsable(actor: AuthUser) {
    if (!actor.clubId) {
      throw new ForbiddenException('Club responsable must belong to a club');
    }
    return this.listPendingUsersByClub(actor.clubId);
  }

  async approveOrRejectUser(actor: AuthUser, userId: string, dto: ApproveUserDto) {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (!user.clubId || !actor.clubId || String(user.clubId) !== actor.clubId) {
      throw new ForbiddenException('Cannot approve users from another club');
    }

    if (user.status !== UserStatus.PENDING_CLUB_APPROVAL) {
      throw new BadRequestException('Only pending club users can be approved/rejected');
    }

    const before = user.toObject();
    user.status = dto.status;
    await user.save();

    await this.auditService.write({
      clubId: actor.clubId,
      actorUserId: actor.sub,
      actionType: dto.status === UserStatus.ACTIVE ? 'USER_APPROVED' : 'USER_REJECTED',
      entityType: 'User',
      entityId: user.id,
      before,
      after: user.toObject(),
      metadata: { reason: dto.reason }
    });

    const resultObj = user.toObject() as unknown as Record<string, unknown>;
    const sanitized = { ...resultObj };
    delete sanitized.passwordHash;
    delete sanitized.__v;
    return sanitized;
  }

  async listUsersForActor(actor: AuthUser, filters: ListUsersDto) {
    const query: FilterQuery<UserDocument> = {};
    if (actor.role !== Role.ADMIN) {
      query.clubId = actor.clubId ? new Types.ObjectId(actor.clubId) : null;
    }
    if (filters.role) {
      query.role = filters.role;
    }
    if (filters.status) {
      query.status = filters.status;
    }

    return this.userModel.find(query).select(this.listProjection).sort({ createdAt: -1 }).lean();
  }

  async updateUserAsAdmin(actor: AuthUser, userId: string, dto: UpdateUserDto) {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const before = user.toObject();
    const statusChanged = dto.status != null && dto.status !== user.status;

    if (dto.email && dto.email.toLowerCase() !== user.email) {
      const existing = await this.userModel.findOne({ email: dto.email.toLowerCase() });
      if (existing && String(existing._id) !== String(user._id)) {
        throw new BadRequestException('Email already in use');
      }
      user.email = dto.email.toLowerCase();
    }

    if (dto.firstName != null) {
      user.firstName = dto.firstName.trim();
    }
    if (dto.lastName != null) {
      user.lastName = dto.lastName.trim();
    }
    if (dto.phone != null) {
      user.phone = dto.phone.trim();
    }
    if (dto.photoUrl != null) {
      user.photoUrl = dto.photoUrl.trim();
    }
    if (dto.status != null) {
      user.status = dto.status;
    }

    await user.save();

    if (user.clubId) {
      await this.auditService.write({
        clubId: String(user.clubId),
        actorUserId: actor.sub,
        actionType: statusChanged ? 'USER_STATUS_UPDATED' : 'USER_UPDATED',
        entityType: 'User',
        entityId: user.id,
        before,
        after: user.toObject(),
        metadata: {
          by: 'ADMIN',
          ...(statusChanged
            ? {
                previousStatus: before.status,
                nextStatus: user.status
              }
            : {})
        }
      });
    }

    const resultObj = user.toObject() as unknown as Record<string, unknown>;
    const sanitized = { ...resultObj };
    delete sanitized.passwordHash;
    delete sanitized.__v;
    return sanitized;
  }

  async deleteUserAsAdmin(actor: AuthUser, userId: string) {
    if (actor.sub === userId) {
      throw new BadRequestException('You cannot delete your own admin account');
    }

    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const before = user.toObject();
    await user.deleteOne();

    if (before.clubId) {
      await this.auditService.write({
        clubId: String(before.clubId),
        actorUserId: actor.sub,
        actionType: 'USER_DELETED',
        entityType: 'User',
        entityId: userId,
        before,
        after: null,
        metadata: { by: 'ADMIN' }
      });
    }

    return { success: true };
  }
}
