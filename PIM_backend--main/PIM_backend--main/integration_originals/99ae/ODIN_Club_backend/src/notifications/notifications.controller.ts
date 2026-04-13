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
import {
  EmergencyNotificationDto,
  ListNotificationsDto,
  MarkNotificationsReadDto,
  MedicalAlertDto,
  TrainingReminderDto
} from './dto/notifications.dto';
import { NotificationsService } from './notifications.service';

@ApiTags('notifications')
@ApiBearerAuth()
@Controller('notifications')
@UseGuards(JwtAuthGuard, ActiveUserGuard, RolesGuard, PermissionsGuard)
@Roles(
  Role.CLUB_RESPONSABLE,
  Role.FINANCIER,
  Role.JOUEUR,
  Role.STAFF_TECHNIQUE,
  Role.STAFF_MEDICAL
)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Permissions(Permission.NOTIF_READ)
  @Get()
  list(@CurrentUser() actor: AuthUser, @Query() query: ListNotificationsDto) {
    return this.notificationsService.listForActor(actor, query);
  }

  @Permissions(Permission.NOTIF_READ)
  @Sse('stream')
  stream(@CurrentUser() actor: AuthUser) {
    return this.notificationsService.streamForUser(actor);
  }

  @Permissions(Permission.NOTIF_WRITE)
  @Post('mark-read')
  markRead(@CurrentUser() actor: AuthUser, @Body() dto: MarkNotificationsReadDto) {
    return this.notificationsService.markReadMany(actor, dto);
  }

  @Permissions(Permission.NOTIF_WRITE)
  @Post(':id/read')
  markReadOne(@CurrentUser() actor: AuthUser, @Param('id') id: string) {
    return this.notificationsService.markReadOne(actor, id);
  }

  @Permissions(Permission.NOTIF_WRITE)
  @Delete(':id')
  deleteOne(@CurrentUser() actor: AuthUser, @Param('id') id: string) {
    return this.notificationsService.deleteOne(actor, id);
  }

  @Roles(Role.CLUB_RESPONSABLE, Role.STAFF_TECHNIQUE, Role.STAFF_MEDICAL)
  @Permissions(Permission.EMERGENCY_SEND)
  @Post('emergency')
  emergency(@CurrentUser() actor: AuthUser, @Body() dto: EmergencyNotificationDto) {
    return this.notificationsService.createEmergency(actor, dto);
  }

  @Roles(Role.STAFF_MEDICAL)
  @Permissions(Permission.MEDICAL_ALERT_SEND)
  @Post('medical-alert')
  medicalAlert(@CurrentUser() actor: AuthUser, @Body() dto: MedicalAlertDto) {
    return this.notificationsService.createMedicalAlert(actor, dto);
  }

  @Roles(Role.STAFF_TECHNIQUE, Role.CLUB_RESPONSABLE)
  @Permissions(Permission.TRAINING_REMINDER_SEND)
  @Post('training-reminder')
  trainingReminder(@CurrentUser() actor: AuthUser, @Body() dto: TrainingReminderDto) {
    return this.notificationsService.scheduleTrainingReminder(actor, dto);
  }
}
