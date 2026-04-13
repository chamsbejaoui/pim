import { IsOptional, IsString, Length, IsEmail } from 'class-validator';

export class VerifyEmailTokenDto {
  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  @Length(6, 6)
  code?: string;

  @IsOptional()
  @IsString()
  token?: string;
}
