import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayNotEmpty,
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsMongoId,
  IsOptional,
  IsString,
  Length,
  MaxLength
} from 'class-validator';
import { Role } from '../../common/enums/role.enum';
import { NotificationType } from '../../common/enums/notification-type.enum';

const parseBoolean = ({ value }: { value: unknown }) => {
  if (value === undefined || value === null || value === '') {
    return undefined;
  }
  if (typeof value === 'boolean') {
    return value;
  }
  if (typeof value === 'string') {
    return value.toLowerCase() === 'true';
  }
  return Boolean(value);
};

export class ListNotificationsDto {
  @IsOptional()
  @Transform(parseBoolean)
  @IsBoolean()
  unreadOnly?: boolean;

  @IsOptional()
  @IsEnum(NotificationType)
  type?: NotificationType;

  @IsOptional()
  @Transform(({ value }) => Number(value))
  limit?: number;
}

export class MarkNotificationsReadDto {
  @IsArray()
  @ArrayNotEmpty()
  @ArrayMaxSize(200)
  @IsMongoId({ each: true })
  notificationIds: string[];
}

export class EmergencyNotificationDto {
  @IsString()
  @Length(2, 120)
  title: string;

  @IsString()
  @Length(2, 400)
  body: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  severity?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(200)
  @IsMongoId({ each: true })
  targetUserIds?: string[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsEnum(Role, { each: true })
  targetRoles?: Role[];
}

export class MedicalAlertDto {
  @IsString()
  @Length(2, 120)
  title: string;

  @IsString()
  @Length(2, 400)
  body: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  severity?: string;

  @IsArray()
  @ArrayNotEmpty()
  @ArrayMaxSize(120)
  @IsMongoId({ each: true })
  targetPlayerIds: string[];

  @IsOptional()
  @IsBoolean()
  @Transform(parseBoolean)
  includeCoaches?: boolean;

  @IsOptional()
  @IsBoolean()
  @Transform(parseBoolean)
  includeResponsables?: boolean;

  @IsOptional()
  @IsBoolean()
  @Transform(parseBoolean)
  confidential?: boolean;
}

export class TrainingReminderDto {
  @IsString()
  @Length(2, 120)
  title: string;

  @IsString()
  @Length(2, 400)
  body: string;

  @IsDateString()
  scheduleAt: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  trainingId?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(200)
  @IsMongoId({ each: true })
  targetUserIds?: string[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsEnum(Role, { each: true })
  targetRoles?: Role[];
}
