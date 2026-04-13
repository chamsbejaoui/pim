import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Permissions } from '../common/decorators/permissions.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Permission } from '../common/enums/permission.enum';
import { Role } from '../common/enums/role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { ActiveUserGuard } from '../common/guards/active-user.guard';
import { ClubScopeGuard } from '../common/guards/club-scope.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { ApproveUserDto } from './dto/approve-user.dto';
import { ListUsersDto } from './dto/list-users.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UsersService } from './users.service';

@ApiTags('users')
@ApiBearerAuth()
@Controller('users')
@UseGuards(JwtAuthGuard, ActiveUserGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return user;
  }

  @Get('profile')
  profile(@CurrentUser() user: AuthUser) {
    return this.usersService.getProfile(user.sub);
  }

  @UseGuards(RolesGuard, PermissionsGuard)
  @Roles(Role.ADMIN, Role.CLUB_RESPONSABLE)
  @Permissions(Permission.USERS_PENDING_READ)
  @Get('pending')
  listPendingUsers(@CurrentUser() user: AuthUser) {
    if (user.role === Role.ADMIN) {
      return this.usersService.listPendingUsersForAdmin();
    }
    return this.usersService.listPendingUsersForResponsable(user);
  }

  @UseGuards(RolesGuard, PermissionsGuard)
  @Roles(Role.CLUB_RESPONSABLE)
  @Permissions(Permission.USERS_APPROVE)
  @Patch(':userId/approval')
  approveOrRejectUser(
    @CurrentUser() user: AuthUser,
    @Param('userId') userId: string,
    @Body() dto: ApproveUserDto
  ) {
    return this.usersService.approveOrRejectUser(user, userId, dto);
  }

  @UseGuards(RolesGuard, PermissionsGuard)
  @Roles(Role.ADMIN)
  @Permissions(Permission.USERS_APPROVE)
  @Patch(':userId/approval/admin')
  approveOrRejectUserAsAdmin(
    @CurrentUser() user: AuthUser,
    @Param('userId') userId: string,
    @Body() dto: ApproveUserDto
  ) {
    return this.usersService.approveOrRejectUserAsAdmin(user, userId, dto);
  }

  @UseGuards(RolesGuard, PermissionsGuard)
  @Roles(Role.ADMIN)
  @Permissions(Permission.USERS_APPROVE)
  @Post(':userId/approve')
  approveUser(@CurrentUser() user: AuthUser, @Param('userId') userId: string) {
    return this.usersService.approveOrRejectUserAsAdmin(user, userId, {
      status: UserStatus.ACTIVE
    });
  }

  @UseGuards(RolesGuard, PermissionsGuard)
  @Roles(Role.ADMIN)
  @Permissions(Permission.USERS_APPROVE)
  @Post(':userId/reject')
  rejectUser(@CurrentUser() user: AuthUser, @Param('userId') userId: string) {
    return this.usersService.approveOrRejectUserAsAdmin(user, userId, {
      status: UserStatus.REJECTED
    });
  }

  @UseGuards(RolesGuard, PermissionsGuard, ClubScopeGuard)
  @Roles(Role.ADMIN, Role.CLUB_RESPONSABLE, Role.FINANCIER)
  @Permissions(Permission.USERS_READ)
  @Get()
  listUsers(@CurrentUser() user: AuthUser, @Query() filters: ListUsersDto) {
    return this.usersService.listUsersForActor(user, filters);
  }

  @UseGuards(RolesGuard, PermissionsGuard)
  @Roles(Role.ADMIN)
  @Permissions(Permission.USERS_UPDATE)
  @Patch(':userId')
  updateUser(
    @CurrentUser() actor: AuthUser,
    @Param('userId') userId: string,
    @Body() dto: UpdateUserDto
  ) {
    return this.usersService.updateUserAsAdmin(actor, userId, dto);
  }

  @UseGuards(RolesGuard, PermissionsGuard)
  @Roles(Role.ADMIN)
  @Permissions(Permission.USERS_DELETE)
  @Delete(':userId')
  deleteUser(@CurrentUser() actor: AuthUser, @Param('userId') userId: string) {
    return this.usersService.deleteUserAsAdmin(actor, userId);
  }
}
