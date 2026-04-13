import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  Sse,
  UseGuards
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Permissions } from '../common/decorators/permissions.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Permission } from '../common/enums/permission.enum';
import { Role } from '../common/enums/role.enum';
import { ActiveUserGuard } from '../common/guards/active-user.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { ChatService } from './chat.service';
import {
  CreateAnnouncementDto,
  CreateDirectConversationDto,
  CreateGroupConversationDto,
  DeleteMessageDto,
  ListChatUsersDto,
  ListConversationsDto,
  ListMessagesDto,
  SendMessageDto
} from './dto/chat.dto';

@ApiTags('chat')
@ApiBearerAuth()
@Controller('chat')
@UseGuards(JwtAuthGuard, ActiveUserGuard, RolesGuard, PermissionsGuard)
@Roles(
  Role.CLUB_RESPONSABLE,
  Role.FINANCIER,
  Role.JOUEUR,
  Role.STAFF_TECHNIQUE,
  Role.STAFF_MEDICAL
)
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Permissions(Permission.CHAT_READ)
  @Get('users')
  users(@CurrentUser() actor: AuthUser, @Query() query: ListChatUsersDto) {
    return this.chatService.listSameClubUsers(actor, query);
  }

  @Permissions(Permission.CHAT_READ)
  @Get('conversations')
  listConversations(
    @CurrentUser() actor: AuthUser,
    @Query() query: ListConversationsDto
  ): Promise<unknown> {
    return this.chatService.listConversations(actor, query);
  }

  @Permissions(Permission.CHAT_WRITE)
  @Post('conversations/direct')
  createDirect(@CurrentUser() actor: AuthUser, @Body() dto: CreateDirectConversationDto) {
    return this.chatService.createDirectConversation(actor, dto);
  }

  @Permissions(Permission.CHAT_WRITE)
  @Post('conversations/group')
  createGroup(@CurrentUser() actor: AuthUser, @Body() dto: CreateGroupConversationDto) {
    return this.chatService.createGroupConversation(actor, dto);
  }

  @Permissions(Permission.CHAT_READ)
  @Get('conversations/:id/messages')
  listMessages(
    @CurrentUser() actor: AuthUser,
    @Param('id') conversationId: string,
    @Query() query: ListMessagesDto
  ) {
    return this.chatService.listMessages(actor, conversationId, query);
  }

  @Permissions(Permission.CHAT_WRITE)
  @Post('conversations/:id/messages')
  sendMessage(
    @CurrentUser() actor: AuthUser,
    @Param('id') conversationId: string,
    @Body() dto: SendMessageDto
  ) {
    return this.chatService.sendMessage(actor, conversationId, dto);
  }

  @Permissions(Permission.CHAT_WRITE)
  @Delete('messages/:id')
  deleteMessage(
    @CurrentUser() actor: AuthUser,
    @Param('id') messageId: string,
    @Query() query: DeleteMessageDto
  ) {
    return this.chatService.deleteMessage(actor, messageId, query);
  }

  @Roles(Role.STAFF_TECHNIQUE, Role.CLUB_RESPONSABLE)
  @Permissions(Permission.ANNOUNCEMENT_SEND)
  @Post('announcements')
  announcement(@CurrentUser() actor: AuthUser, @Body() dto: CreateAnnouncementDto) {
    return this.chatService.createAnnouncement(actor, dto);
  }

  @Permissions(Permission.CHAT_READ)
  @Sse('stream')
  stream(@CurrentUser() actor: AuthUser) {
    return this.chatService.streamForActor(actor);
  }
}
