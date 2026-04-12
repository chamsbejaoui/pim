import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ClubStatus } from '../common/enums/club-status.enum';
import { Role } from '../common/enums/role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { AuditService } from '../audit/audit.service';
import { ClubApprovalDto } from './dto/club-approval.dto';
import { Club, ClubDocument } from './schemas/club.schema';
import { User, UserDocument } from '../users/schemas/user.schema';

@Injectable()
export class ClubsService {
  constructor(
    @InjectModel(Club.name) private readonly clubModel: Model<ClubDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    private readonly auditService: AuditService
  ) {}

  async listPendingClubs() {
    return this.clubModel.find({ status: ClubStatus.PENDING }).sort({ createdAt: -1 }).lean();
  }

  async listActiveClubs() {
    return this.clubModel.find({ status: ClubStatus.ACTIVE }).sort({ name: 1 }).lean();
  }

  async approveOrRejectClub(clubId: string, dto: ClubApprovalDto, actorUserId: string) {
    const club = await this.clubModel.findById(clubId);
    if (!club) {
      throw new NotFoundException('Club not found');
    }

    const before = club.toObject();
    club.status = dto.status;
    await club.save();

    const responsable = await this.userModel.findOne({
      clubId: new Types.ObjectId(club.id),
      role: Role.CLUB_RESPONSABLE
    });

    if (responsable) {
      responsable.status =
        dto.status === ClubStatus.ACTIVE ? UserStatus.ACTIVE : UserStatus.REJECTED;
      await responsable.save();
    }

    await this.auditService.write({
      clubId: club.id,
      actorUserId,
      actionType: dto.status === ClubStatus.ACTIVE ? 'CLUB_APPROVED' : 'CLUB_REJECTED',
      entityType: 'Club',
      entityId: club.id,
      before,
      after: club.toObject(),
      metadata: { reason: dto.reason }
    });

    return club;
  }
}
