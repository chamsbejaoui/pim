import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  UnauthorizedException
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Model, Types } from 'mongoose';
import * as nodemailer from 'nodemailer';
import { compareValue, hashValue } from '../common/utils/hash.util';
import { Role } from '../common/enums/role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { ClubStatus } from '../common/enums/club-status.enum';
import { Club, ClubDocument } from '../clubs/schemas/club.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { OtpService } from '../otp/otp.service';
import { AuditService } from '../audit/audit.service';
import { LoginDto } from './dto/login.dto';
import { RequestForgotPasswordDto, ResetPasswordDto } from './dto/forgot-password.dto';
import { RegisterDto } from './dto/register.dto';
import { RegisterMemberDto } from './dto/register-member.dto';
import { RegisterResponsableDto } from './dto/register-responsable.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import {
  OTP_PURPOSE_EMAIL_VERIFY,
  OTP_PURPOSE_FORGOT_PASSWORD,
  OTP_PURPOSE_SENSITIVE_ACTION
} from './auth.constants';
import { generateSixDigitCode } from '../common/utils/code-generator.util';

export interface SensitiveVerificationInput {
  password?: string;
  otpCode?: string;
  actionType: string;
  amount: number;
}

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(Club.name) private readonly clubModel: Model<ClubDocument>,
    private readonly jwtService: JwtService,
    private readonly otpService: OtpService,
    private readonly auditService: AuditService,
    private readonly configService: ConfigService
  ) {}

  async registerResponsable(dto: RegisterResponsableDto) {
    const existing = await this.userModel.findOne({ email: dto.email.toLowerCase() });
    if (existing) {
      throw new BadRequestException('Email already in use');
    }

    const passwordHash = await hashValue(dto.password);
    const user = await this.userModel.create({
      email: dto.email.toLowerCase(),
      passwordHash,
      firstName: dto.firstName,
      lastName: dto.lastName,
      phone: dto.phone,
      photoUrl: dto.photoUrl,
      role: Role.CLUB_RESPONSABLE,
      status: UserStatus.PENDING_ADMIN_APPROVAL,
      clubId: null,
      isEmailVerified: true,
      isActive: false,
      isApprovedByAdmin: false
    });

    const club = await this.clubModel.create({
      name: dto.clubName,
      league: dto.league,
      country: dto.country,
      city: dto.city,
      logoUrl: dto.logoUrl,
      status: ClubStatus.PENDING,
      createdByUserId: new Types.ObjectId(user.id),
      responsableUserId: new Types.ObjectId(user.id)
    });

    user.clubId = new Types.ObjectId(club.id);
    await user.save();

    await this.auditService.write({
      clubId: club.id,
      actorUserId: user.id,
      actionType: 'REGISTER_RESPONSABLE',
      entityType: 'User',
      entityId: user.id,
      before: null,
      after: user.toObject(),
      metadata: { clubId: club.id }
    });

    return {
      userId: user.id,
      clubId: club.id,
      status: user.status,
      clubStatus: club.status,
      nextStep: 'Await admin approval'
    };
  }

  async registerMember(dto: RegisterMemberDto) {
    if (
      dto.role !== Role.JOUEUR &&
      dto.role !== Role.STAFF_TECHNIQUE &&
      dto.role !== Role.STAFF_MEDICAL &&
      dto.role !== Role.FINANCIER
    ) {
      throw new BadRequestException('Invalid role for this registration endpoint');
    }

    if (dto.role === Role.JOUEUR && !dto.position) {
      throw new BadRequestException('position is required for JOUEUR');
    }

    if ([Role.STAFF_TECHNIQUE, Role.STAFF_MEDICAL].includes(dto.role) && !dto.jobTitle) {
      throw new BadRequestException('jobTitle is required for staff roles');
    }

    const club = await this.clubModel.findOne({ _id: dto.clubId, status: ClubStatus.ACTIVE });
    if (!club) {
      throw new BadRequestException('Club must exist and be ACTIVE');
    }

    const existing = await this.userModel.findOne({ email: dto.email.toLowerCase() });
    if (existing) {
      throw new BadRequestException('Email already in use');
    }

    const passwordHash = await hashValue(dto.password);
    const user = await this.userModel.create({
      clubId: new Types.ObjectId(dto.clubId),
      email: dto.email.toLowerCase(),
      passwordHash,
      firstName: dto.firstName,
      lastName: dto.lastName,
      phone: dto.phone,
      photoUrl: dto.photoUrl,
      role: dto.role,
      status: UserStatus.PENDING_CLUB_APPROVAL,
      isActive: false,
      isApprovedByAdmin: true,
      position: dto.role === Role.JOUEUR ? dto.position : undefined,
      jobTitle:
        dto.role === Role.STAFF_TECHNIQUE || dto.role === Role.STAFF_MEDICAL
          ? dto.jobTitle
          : undefined,
      isEmailVerified: true
    });

    await this.auditService.write({
      clubId: dto.clubId,
      actorUserId: user.id,
      actionType: 'REGISTER_MEMBER',
      entityType: 'User',
      entityId: user.id,
      before: null,
      after: user.toObject(),
      metadata: { role: dto.role }
    });

    return {
      userId: user.id,
      status: user.status,
      nextStep: 'Await club approval'
    };
  }

  async verifyEmail(dto: VerifyEmailDto) {
    const user = await this.userModel.findOne({ email: dto.email.toLowerCase() });
    if (!user) {
      throw new UnauthorizedException('Invalid verification request');
    }

    await this.otpService.verifyCode(user.email, OTP_PURPOSE_EMAIL_VERIFY, dto.code, user.id);

    user.isEmailVerified = true;
    await user.save();

    return { success: true };
  }

  async resendEmailVerification(email: string) {
    const user = await this.userModel.findOne({ email: email.toLowerCase() });
    if (!user) {
      return { success: true };
    }

    await this.otpService.generateAndSendCode(user.email, OTP_PURPOSE_EMAIL_VERIFY, user.id);
    return { success: true };
  }

  async login(dto: LoginDto) {
    const user = await this.userModel.findOne({ email: dto.email.toLowerCase() });
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.passwordHash) {
      throw new UnauthorizedException('Password not set');
    }

    const valid = await compareValue(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.isEmailVerified) {
      throw new ForbiddenException('Email is not verified');
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException(`User is not active: ${user.status}`);
    }

    const jwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      clubId: user.clubId ? String(user.clubId) : null,
      status: user.status
    };
    const club = user.clubId
      ? await this.clubModel.findById(user.clubId).select('name').lean<{ name?: string }>()
      : null;

    const token = await this.jwtService.signAsync(jwtPayload);
    return {
      accessToken: token,
      access_token: token,
      user: {
        ...jwtPayload,
        firstName: user.firstName,
        lastName: user.lastName,
        photoUrl: user.photoUrl ?? null,
        clubName: club?.name ?? null
      }
    };
  }

  async requestForgotPassword(dto: RequestForgotPasswordDto) {
    const user = await this.userModel.findOne({ email: dto.email.toLowerCase() });
    if (!user) {
      return { success: true };
    }

    await this.otpService.generateAndSendCode(user.email, OTP_PURPOSE_FORGOT_PASSWORD, user.id);
    return { success: true };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const user = await this.userModel.findOne({ email: dto.email.toLowerCase() });
    if (!user) {
      throw new UnauthorizedException('Invalid reset request');
    }

    await this.otpService.verifyCode(user.email, OTP_PURPOSE_FORGOT_PASSWORD, dto.code, user.id);
    user.passwordHash = await hashValue(dto.newPassword);
    await user.save();

    return { success: true };
  }

  async register(dto: RegisterDto) {
    const existing = await this.userModel.findOne({ email: dto.email.toLowerCase() });
    if (existing) {
      throw new BadRequestException('Email already in use');
    }

    const passwordHash = await hashValue(dto.password);
    const verificationCode = generateSixDigitCode();

    const user = await this.userModel.create({
      email: dto.email.toLowerCase(),
      passwordHash,
      firstName: dto.firstName,
      lastName: dto.lastName,
      phone: dto.phone,
      role: dto.role,
      status: UserStatus.PENDING_ADMIN_APPROVAL,
      position: dto.role === Role.JOUEUR ? dto.position : undefined,
      isEmailVerified: false,
      isActive: false,
      isApprovedByAdmin: false,
      emailVerificationToken: verificationCode
    });

    await this.sendAuthEmail(
      user.email,
      'Verify your email',
      `Your verification code is ${verificationCode}.`
    );

    const userObj = user.toObject() as unknown as Record<string, unknown>;
    delete userObj.passwordHash;
    delete userObj.__v;

    return {
      message:
        'Registration successful. Please verify your email and await admin approval.',
      user: userObj
    };
  }

  async verifyEmailToken(token: string) {
    const user = await this.userModel.findOne({ emailVerificationToken: token });
    if (!user) {
      throw new UnauthorizedException('Invalid verification token');
    }

    user.isEmailVerified = true;
    user.emailVerificationToken = null;
    await user.save();

    return { success: true };
  }

  async forgotPasswordToken(email: string) {
    const user = await this.userModel.findOne({ email: email.toLowerCase() });
    if (!user) {
      return { success: true };
    }

    const resetCode = generateSixDigitCode();
    const resetExpires = new Date();
    resetExpires.setHours(resetExpires.getHours() + 1);

    user.passwordResetToken = resetCode;
    user.passwordResetExpires = resetExpires;
    await user.save();

    await this.sendAuthEmail(
      user.email,
      'Password reset code',
      `Your password reset code is ${resetCode}. It expires in 1 hour.`
    );

    return { success: true };
  }

  async resetPasswordToken(token: string, newPassword: string) {
    const user = await this.userModel.findOne({
      passwordResetToken: token,
      passwordResetExpires: { $gt: new Date() }
    });

    if (!user) {
      throw new UnauthorizedException('Invalid or expired reset token');
    }

    user.passwordHash = await hashValue(newPassword);
    user.passwordResetToken = null;
    user.passwordResetExpires = null;
    await user.save();

    return { success: true };
  }

  async validateGoogleUser(googleUser: any) {
    let user = await this.userModel.findOne({ googleId: googleUser.googleId });

    if (!user && googleUser.email) {
      user = await this.userModel.findOne({ email: googleUser.email.toLowerCase() });
      if (user) {
        user.googleId = googleUser.googleId;
        user.isEmailVerified = true;
        await user.save();
      }
    }

    if (!user) {
      user = await this.userModel.create({
        email: googleUser.email?.toLowerCase(),
        firstName: googleUser.firstName,
        lastName: googleUser.lastName,
        googleId: googleUser.googleId,
        role: Role.JOUEUR,
        status: UserStatus.PENDING_ADMIN_APPROVAL,
        isEmailVerified: true,
        isActive: false,
        isApprovedByAdmin: false
      });
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('Your account is pending admin approval.');
    }

    const jwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      clubId: user.clubId ? String(user.clubId) : null,
      status: user.status
    };

    const token = await this.jwtService.signAsync(jwtPayload);
    return {
      accessToken: token,
      access_token: token,
      user: {
        ...jwtPayload,
        firstName: user.firstName,
        lastName: user.lastName,
        photoUrl: user.photoUrl ?? null
      }
    };
  }

  async requestSensitiveActionOtp(userId: string, actionType: string) {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    await this.otpService.generateAndSendCode(user.email, OTP_PURPOSE_SENSITIVE_ACTION, user.id);

    return { success: true, actionType };
  }

  async verifySensitiveAction(userId: string, input: SensitiveVerificationInput): Promise<boolean> {
    const user = await this.userModel.findById(userId);
    if (!user) {
      return false;
    }

    const usingPassword = !!input.password;
    const usingOtp = !!input.otpCode;
    if (!usingPassword && !usingOtp) {
      return false;
    }

    if (usingPassword) {
      if (!user.passwordHash) {
        return false;
      }
      const passwordOk = await compareValue(input.password as string, user.passwordHash);
      if (!passwordOk) {
        return false;
      }
    }

    if (usingOtp) {
      await this.otpService.verifyCode(
        user.email,
        OTP_PURPOSE_SENSITIVE_ACTION,
        input.otpCode as string,
        user.id
      );
    }

    const dailyCountLimit = Number(
      this.configService.get<string>('SENSITIVE_DAILY_LIMIT_COUNT', '10')
    );
    const dailyAmountLimit = Number(
      this.configService.get<string>('SENSITIVE_DAILY_LIMIT_AMOUNT', '10000000')
    );
    const perActionLimit = Number(
      this.configService.get<string>('SENSITIVE_PER_ACTION_AMOUNT_LIMIT', '5000000')
    );

    if (input.amount && input.amount > perActionLimit) {
      return false;
    }

    const dayStart = new Date();
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date();
    dayEnd.setHours(23, 59, 59, 999);

    const summary = await this.auditService.getDailySensitiveSummary(
      user.id,
      input.actionType,
      dayStart,
      dayEnd
    );

    if (summary.count >= dailyCountLimit) {
      return false;
    }

    if (input.amount && summary.totalAmount + input.amount > dailyAmountLimit) {
      return false;
    }

    return true;
  }

  private async sendAuthEmail(to: string, subject: string, text: string): Promise<void> {
    const host = this.configService.get<string>('SMTP_HOST');
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');
    const from = this.configService.get<string>('SMTP_FROM', 'no-reply@odin.local');
    const port = Number(this.configService.get<string>('SMTP_PORT', '587'));

    if (!host || !user || !pass) {
      // eslint-disable-next-line no-console
      console.log(`[MAIL-DEV] to=${to} subject=${subject} text=${text}`);
      return;
    }

    const transporter = nodemailer.createTransport({
      host,
      port,
      secure: false,
      auth: { user, pass }
    });
    await transporter.sendMail({ from, to, subject, text });
  }
}
