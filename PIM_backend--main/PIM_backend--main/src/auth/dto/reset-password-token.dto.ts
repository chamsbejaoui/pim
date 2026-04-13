import { IsString, MinLength } from 'class-validator';

export class ResetPasswordTokenDto {
  @IsString()
  token: string;

  @IsString()
  @MinLength(8)
  newPassword: string;
}
