import { IsEmail, IsEnum, IsMongoId, IsOptional, IsString, MinLength } from 'class-validator';
import { Role } from '../../common/enums/role.enum';

export class RegisterMemberDto {
  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsString()
  firstName: string;

  @IsString()
  lastName: string;

  @IsString()
  phone: string;

  @IsEmail()
  email: string;

  @MinLength(8)
  password: string;

  @IsEnum(Role)
  role: Role.JOUEUR | Role.STAFF_TECHNIQUE | Role.STAFF_MEDICAL | Role.FINANCIER;

  @IsMongoId()
  clubId: string;

  @IsOptional()
  @IsString()
  position?: string;

  @IsOptional()
  @IsString()
  jobTitle?: string;
}
