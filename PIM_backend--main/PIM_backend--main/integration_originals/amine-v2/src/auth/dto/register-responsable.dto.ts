import { IsEmail, IsOptional, IsString, MinLength } from 'class-validator';

export class RegisterResponsableDto {
  @IsString()
  clubName: string;

  @IsString()
  league: string;

  @IsOptional()
  @IsString()
  country?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  logoUrl?: string;

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
}
