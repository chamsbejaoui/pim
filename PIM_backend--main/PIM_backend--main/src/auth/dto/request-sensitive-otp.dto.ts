import { IsString } from 'class-validator';

export class RequestSensitiveOtpDto {
  @IsString()
  actionType: string;
}
