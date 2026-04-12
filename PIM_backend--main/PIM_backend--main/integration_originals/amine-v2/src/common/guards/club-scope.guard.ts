import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Role } from '../enums/role.enum';
import { AuthUser } from '../interfaces/auth-user.interface';

@Injectable()
export class ClubScopeGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user as AuthUser;
    if (!user) {
      throw new ForbiddenException('Authentication required');
    }

    if (user.role === Role.ADMIN) {
      return true;
    }

    const bodyClubId = request.body?.clubId;
    const paramsClubId = request.params?.clubId;
    const queryClubId = request.query?.clubId;
    const targetClubId = bodyClubId || paramsClubId || queryClubId || user.clubId;

    if (!user.clubId || !targetClubId || user.clubId !== targetClubId) {
      throw new ForbiddenException('Cross-club access is forbidden');
    }

    request.clubId = targetClubId;
    return true;
  }
}
