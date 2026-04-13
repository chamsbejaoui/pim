import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserService } from '../user/user.service';
import { EmailService } from '../email/email.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { UserRole } from '../user/entities/user.entity';
import { generateSixDigitCode } from '../utils/code-generator';

@Injectable()
export class AuthService {
  constructor(
    private userService: UserService,
    private jwtService: JwtService,
    private emailService: EmailService,
  ) {}

  async register(registerDto: RegisterDto) {
    const existingUser = await this.userService.findByEmail(registerDto.email);
    if (existingUser) {
      throw new ConflictException('Email already registered');
    }

    const verificationCode = generateSixDigitCode();
    const user = await this.userService.create({
      ...registerDto,
      emailVerificationToken: verificationCode,
      isEmailVerified: false,
      isActive: false,
      isApprovedByAdmin: false,
    });

    // Send verification email
    await this.emailService.sendVerificationEmail(user.email, verificationCode);

    const { password, emailVerificationToken, passwordResetToken, ...result } = user;
    return {
      message: 'Registration successful. Please check your email to verify your account. Your account will be activated after admin approval.',
      user: result,
    };
  }

  async login(loginDto: LoginDto) {
    const user = await this.userService.findByEmail(loginDto.email);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.isEmailVerified) {
      throw new UnauthorizedException('Please verify your email before logging in');
    }

    if (!user.isApprovedByAdmin) {
      throw new UnauthorizedException('Your account is pending admin approval. Please wait for admin confirmation.');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Account is deactivated');
    }

    const isPasswordValid = await this.userService.validatePassword(user, loginDto.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const payload = { email: user.email, sub: user._id.toString(), role: user.role };
    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user._id.toString(),
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
      },
    };
  }

  async verifyEmail(code: string) {
    const user = await this.userService.verifyEmail(code);
    return {
      message: 'Email verified successfully',
      user: {
        id: user._id.toString(),
        email: user.email,
        isEmailVerified: user.isEmailVerified,
      },
    };
  }

  async forgotPassword(email: string) {
    const user = await this.userService.findByEmail(email);
    if (!user) {
      // Don't reveal if email exists or not for security
      return {
        message: 'If the email exists, a password reset link has been sent.',
      };
    }

    const resetToken = await this.userService.setPasswordResetToken(email);
    await this.emailService.sendPasswordResetEmail(email, resetToken);

    return {
      message: 'If the email exists, a password reset link has been sent.',
    };
  }

  async resetPassword(code: string, newPassword: string) {
    await this.userService.resetPassword(code, newPassword);
    return {
      message: 'Password reset successfully',
    };
  }

  async validateGoogleUser(googleUser: any): Promise<any> {
    let user = await this.userService.findByGoogleId(googleUser.googleId);

    if (!user) {
      // Check if user exists with this email
      const existingUser = await this.userService.findByEmail(googleUser.email);
      if (existingUser) {
        // Link Google account to existing user
        user = await this.userService.update(existingUser._id.toString(), {
          googleId: googleUser.googleId,
          isEmailVerified: true,
        });
      } else {
        // Create new user
        user = await this.userService.create({
          email: googleUser.email,
          firstName: googleUser.firstName,
          lastName: googleUser.lastName,
          googleId: googleUser.googleId,
          isEmailVerified: true,
          isActive: false,
          isApprovedByAdmin: false,
          role: UserRole.JOUEUR, // Default role
        });
      }
    }

    // Check if user is approved by admin
    if (!user.isApprovedByAdmin) {
      throw new UnauthorizedException('Your account is pending admin approval. Please wait for admin confirmation.');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Account is deactivated');
    }

    const payload = { email: user.email, sub: user._id.toString(), role: user.role };
    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user._id.toString(),
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
      },
    };
  }
}
