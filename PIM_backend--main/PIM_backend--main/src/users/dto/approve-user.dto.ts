import { IsEnum, IsOptional, IsString } from 'class-validator';
import { UserStatus } from '../../common/enums/user-status.enum';

export class ApproveUserDto {
  @IsEnum(UserStatus)
  status: UserStatus.ACTIVE | UserStatus.REJECTED;

  @IsOptional()
  @IsString()
  reason?: string;
}
