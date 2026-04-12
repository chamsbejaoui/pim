import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Role } from '../enums/role.enum';
import { ClubScopeGuard } from './club-scope.guard';

describe('ClubScopeGuard', () => {
  const guard = new ClubScopeGuard();

  it('allows admin', () => {
    const context = {
      switchToHttp: () => ({
        getRequest: () => ({
          user: { role: Role.ADMIN, clubId: null },
          params: {},
          body: {},
          query: {}
        })
      })
    } as ExecutionContext;

    expect(guard.canActivate(context)).toBe(true);
  });

  it('rejects cross-club access', () => {
    const context = {
      switchToHttp: () => ({
        getRequest: () => ({
          user: { role: Role.FINANCIER, clubId: 'club-a' },
          params: { clubId: 'club-b' },
          body: {},
          query: {}
        })
      })
    } as ExecutionContext;

    expect(() => guard.canActivate(context)).toThrow(ForbiddenException);
  });
});
