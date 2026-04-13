import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as nodemailer from 'nodemailer';
import { compareValue, hashValue } from '../common/utils/hash.util';
import { OtpCode, OtpCodeDocument } from './schemas/otp-code.schema';

const OTP_LENGTH = 6;
const OTP_TTL_MINUTES = 10;

@Injectable()
export class OtpService {
  constructor(
    @InjectModel(OtpCode.name) private readonly otpModel: Model<OtpCodeDocument>,
    private readonly configService: ConfigService
  ) {}

  private generateNumericCode(): string {
    return Array.from({ length: OTP_LENGTH }, () => Math.floor(Math.random() * 10)).join('');
  }

  async generateAndSendCode(email: string, purpose: string, userId?: string) {
    const normalizedEmail = email.toLowerCase();
    const code = this.generateNumericCode();
    const codeHash = await hashValue(code);
    const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000);

    await this.otpModel.updateMany(
      { email: normalizedEmail, purpose, consumedAt: { $exists: false } },
      { $set: { consumedAt: new Date() } }
    );

    await this.otpModel.create({
      email: normalizedEmail,
      userId: userId ? new Types.ObjectId(userId) : undefined,
      purpose,
      codeHash,
      expiresAt
    });

    await this.sendEmail(
      normalizedEmail,
      `Your verification code: ${code}`,
      `Your ${purpose} code is ${code}. It expires in ${OTP_TTL_MINUTES} minutes.`
    );

    return { success: true, expiresAt };
  }

  async verifyCode(
    email: string,
    purpose: string,
    code: string,
    userId?: string
  ): Promise<boolean> {
    const normalizedEmail = email.toLowerCase();
    const query: Record<string, unknown> = {
      email: normalizedEmail,
      purpose,
      consumedAt: { $exists: false },
      expiresAt: { $gt: new Date() }
    };

    if (userId) {
      query.userId = new Types.ObjectId(userId);
    }

    const otp = await this.otpModel.findOne(query).sort({ createdAt: -1 });
    if (!otp) {
      throw new UnauthorizedException('Invalid or expired OTP code');
    }

    const valid = await compareValue(code, otp.codeHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid or expired OTP code');
    }

    otp.consumedAt = new Date();
    await otp.save();
    return true;
  }

  private async sendEmail(to: string, subject: string, text: string): Promise<void> {
    const host = this.configService.get<string>('SMTP_HOST');
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');
    const from = this.configService.get<string>('SMTP_FROM', 'no-reply@odin.local');
    const port = Number(this.configService.get<string>('SMTP_PORT', '587'));

    if (!host || !user || !pass) {
      // fallback for local/dev when SMTP is not configured
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
