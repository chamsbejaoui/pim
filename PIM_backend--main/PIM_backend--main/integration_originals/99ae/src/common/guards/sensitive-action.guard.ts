import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthService } from '../../auth/auth.service';
import { SENSITIVE_ACTION_KEY } from '../decorators/sensitive-action.decorator';
import { AuthUser } from '../interfaces/auth-user.interface';
import { SensitiveActionMetadata } from '../interfaces/sensitive-action-metadata.interface';

@Injectable()
export class SensitiveActionGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly authService: AuthService
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const metadata = this.reflector.getAllAndOverride<SensitiveActionMetadata>(
      SENSITIVE_ACTION_KEY,
      [context.getHandler(), context.getClass()]
    );

    if (!metadata) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user as AuthUser;
    if (!user) {
      throw new UnauthorizedException('Authentication required');
    }

    const sensitivePassword =
      request.headers['x-sensitive-password'] || request.body?.sensitivePassword;
    const sensitiveOtp = request.headers['x-sensitive-otp'] || request.body?.sensitiveOtp;
    const amount = metadata.amountField ? Number(request.body?.[metadata.amountField] ?? 0) : 0;

    const valid = await this.authService.verifySensitiveAction(user.sub, {
      password: typeof sensitivePassword === 'string' ? sensitivePassword : undefined,
      otpCode: typeof sensitiveOtp === 'string' ? sensitiveOtp : undefined,
      actionType: metadata.actionType,
      amount
    });

    if (!valid) {
      throw new ForbiddenException('Sensitive action re-authentication failed');
    }

    return true;
  }
}
