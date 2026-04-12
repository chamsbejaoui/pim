import { Controller, Get, Query, UseGuards } from '@nestjs/common';
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
import { ListAuditDto } from './dto/list-audit.dto';
import { AuditService } from './audit.service';

@ApiTags('audit')
@ApiBearerAuth()
@Controller('audit')
@UseGuards(JwtAuthGuard, ActiveUserGuard, RolesGuard, PermissionsGuard)
@Roles(Role.ADMIN, Role.CLUB_RESPONSABLE, Role.FINANCIER)
@Permissions(Permission.FINANCE_AUDIT_READ)
export class AuditController {
  constructor(private readonly auditService: AuditService) {}

  @Get()
  listAudit(@CurrentUser() actor: AuthUser, @Query() query: ListAuditDto) {
    return this.auditService.listForActor(actor, query);
  }
}
