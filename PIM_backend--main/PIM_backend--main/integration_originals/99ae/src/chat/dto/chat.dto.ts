import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayNotEmpty,
  IsArray,
  IsDateString,
  IsEnum,
  IsIn,
  IsMongoId,
  IsOptional,
  IsString,
  Length,
  MaxLength,
  ValidateNested
} from 'class-validator';
import { Type } from 'class-transformer';
import { Role } from '../../common/enums/role.enum';

export class ListChatUsersDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  search?: string;

  @IsOptional()
  @Transform(({ value }) => Number(value))
  limit?: number;
}

export class ListConversationsDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  search?: string;

  @IsOptional()
  @Transform(({ value }) => Number(value))
  page?: number;

  @IsOptional()
  @Transform(({ value }) => Number(value))
  limit?: number;
}

export class CreateDirectConversationDto {
  @IsMongoId()
  targetUserId: string;
}

export class CreateGroupConversationDto {
  @IsString()
  @Length(2, 100)
  title: string;

  @IsArray()
  @ArrayNotEmpty()
  @ArrayMaxSize(100)
  @IsMongoId({ each: true })
  participantIds: string[];
}

export class ListMessagesDto {
  @IsOptional()
  @Transform(({ value }) => Number(value))
  limit?: number;

  @IsOptional()
  @IsDateString()
  before?: string;
}

export class MessageFileDto {
  @IsString()
  @Length(3, 300)
  url: string;

  @IsString()
  @Length(2, 120)
  mimeType: string;

  @IsString()
  @Length(1, 180)
  name: string;

  @Transform(({ value }) => Number(value))
  size: number;
}

export class SendMessageDto {
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  text?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => MessageFileDto)
  file?: MessageFileDto;

  @IsOptional()
  metadata?: Record<string, unknown>;
}

export class DeleteMessageDto {
  @IsIn(['me', 'everyone'])
  scope: 'me' | 'everyone';
}

export class CreateAnnouncementDto {
  @IsString()
  @Length(2, 120)
  title: string;

  @IsString()
  @Length(2, 1500)
  text: string;

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
