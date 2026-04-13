import { IsEnum, IsOptional, IsString } from 'class-validator';
import { ClubStatus } from '../../common/enums/club-status.enum';

export class ClubApprovalDto {
  @IsEnum(ClubStatus)
  status: ClubStatus.ACTIVE | ClubStatus.REJECTED;

  @IsOptional()
  @IsString()
  reason?: string;
}
