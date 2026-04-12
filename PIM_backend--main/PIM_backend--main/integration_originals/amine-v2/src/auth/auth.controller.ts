import { Body, Controller, Get, Post, Query, UseGuards, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ActiveUserGuard } from '../common/guards/active-user.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { AuthService } from './auth.service';
import { RequestForgotPasswordDto, ResetPasswordDto } from './dto/forgot-password.dto';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { RegisterMemberDto } from './dto/register-member.dto';
import { RegisterResponsableDto } from './dto/register-responsable.dto';
import { RequestSensitiveOtpDto } from './dto/request-sensitive-otp.dto';
import { ResendVerificationDto } from './dto/resend-verification.dto';
import { VerifyEmailTokenDto } from './dto/verify-email-token.dto';
import { ResetPasswordTokenDto } from './dto/reset-password-token.dto';
import { GoogleAuthGuard } from './guards/google-auth.guard';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register/responsable')
  registerResponsable(@Body() dto: RegisterResponsableDto) {
    return this.authService.registerResponsable(dto);
  }

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('register/member')
  registerMember(@Body() dto: RegisterMemberDto) {
    return this.authService.registerMember(dto);
  }

  @Get('verify-email')
  verifyEmailQuery(@Query() dto: VerifyEmailTokenDto) {
    if (dto.token) {
      return this.authService.verifyEmailToken(dto.token);
    }
    if (dto.email && dto.code) {
      return this.authService.verifyEmail({ email: dto.email, code: dto.code });
    }
    return { success: false };
  }

  @Post('verify-email')
  verifyEmail(@Body() dto: VerifyEmailTokenDto) {
    if (dto.token) {
      return this.authService.verifyEmailToken(dto.token);
    }
    if (dto.email && dto.code) {
      return this.authService.verifyEmail({ email: dto.email, code: dto.code });
    }
    return { success: false };
  }

  @Post('resend-verification')
  resendVerification(@Body() dto: ResendVerificationDto) {
    return this.authService.resendEmailVerification(dto.email);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('forgot-password')
  forgotPassword(@Body() dto: RequestForgotPasswordDto) {
    return this.authService.forgotPasswordToken(dto.email);
  }

  @Post('reset-password')
  resetPasswordToken(@Body() dto: ResetPasswordTokenDto) {
    return this.authService.resetPasswordToken(dto.token, dto.newPassword);
  }

  @Post('forgot-password/request')
  requestForgotPassword(@Body() dto: RequestForgotPasswordDto) {
    return this.authService.requestForgotPassword(dto);
  }

  @Post('forgot-password/reset')
  resetPassword(@Body() dto: ResetPasswordDto) {
    return this.authService.resetPassword(dto);
  }

  @Get('google')
  @UseGuards(GoogleAuthGuard)
  googleAuth() {
    return { success: true };
  }

  @Get('google/callback')
  @UseGuards(GoogleAuthGuard)
  googleAuthCallback(@Req() req: any) {
    return this.authService.validateGoogleUser(req.user);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, ActiveUserGuard)
  @Post('sensitive-action/request-otp')
  requestSensitiveOtp(@CurrentUser() user: AuthUser, @Body() dto: RequestSensitiveOtpDto) {
    return this.authService.requestSensitiveActionOtp(user.sub, dto.actionType);
  }
}
