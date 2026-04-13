import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { UserStatus } from '../enums/user-status.enum';
import { ActiveUserGuard } from './active-user.guard';

describe('ActiveUserGuard', () => {
  const guard = new ActiveUserGuard();

  const createContext = (status: UserStatus): ExecutionContext =>
    ({
      switchToHttp: () => ({
        getRequest: () => ({ user: { status } })
      })
    }) as ExecutionContext;

  it('allows ACTIVE users', () => {
    expect(guard.canActivate(createContext(UserStatus.ACTIVE))).toBe(true);
  });

  it('rejects non-active users', () => {
    expect(() => guard.canActivate(createContext(UserStatus.REJECTED))).toThrow(ForbiddenException);
  });
});
