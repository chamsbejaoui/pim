import { Module } from '@nestjs/common';
import { ActiveUserGuard } from '../common/guards/active-user.guard';
import { ClubScopeGuard } from '../common/guards/club-scope.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RolesGuard } from '../common/guards/roles.guard';

@Module({
  providers: [RolesGuard, PermissionsGuard, ClubScopeGuard, ActiveUserGuard],
  exports: [RolesGuard, PermissionsGuard, ClubScopeGuard, ActiveUserGuard]
})
export class RbacModule {}
