import { Body, Controller, Get, Param, Patch, UseGuards } from '@nestjs/common';
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
import { ClubApprovalDto } from './dto/club-approval.dto';
import { ClubsService } from './clubs.service';

@ApiTags('clubs')
@Controller('clubs')
export class ClubsController {
  constructor(private readonly clubsService: ClubsService) {}

  @Get('active')
  listActiveClubs() {
    return this.clubsService.listActiveClubs();
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, ActiveUserGuard, RolesGuard, PermissionsGuard)
  @Roles(Role.ADMIN)
  @Permissions(Permission.CLUBS_PENDING_READ)
  @Get('pending')
  listPendingClubs() {
    return this.clubsService.listPendingClubs();
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, ActiveUserGuard, RolesGuard, PermissionsGuard)
  @Roles(Role.ADMIN)
  @Permissions(Permission.CLUBS_APPROVE)
  @Patch(':clubId/approval')
  approveOrRejectClub(
    @Param('clubId') clubId: string,
    @Body() dto: ClubApprovalDto,
    @CurrentUser() user: AuthUser
  ) {
    return this.clubsService.approveOrRejectClub(clubId, dto, user.sub);
  }
}
