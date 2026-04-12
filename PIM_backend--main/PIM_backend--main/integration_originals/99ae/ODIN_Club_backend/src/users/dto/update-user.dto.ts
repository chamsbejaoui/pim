import { IsEmail, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { IsEnum } from 'class-validator';
import { UserStatus } from '../../common/enums/user-status.enum';

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  firstName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  lastName?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  @MinLength(6)
  @MaxLength(30)
  phone?: string;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus;
}
