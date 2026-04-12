import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService implements OnModuleInit {
  private readonly logger = new Logger(EmailService.name);

  private transporter: nodemailer.Transporter | null = null;

  private isDevelopment = false;
  private smtpUser = '';
  private smtpPass = '';
  private smtpHost = 'smtp.gmail.com';
  private smtpPort = 587;

  constructor(private readonly configService: ConfigService) {}

  async onModuleInit() {
    this.isDevelopment = this.configService.get<string>('NODE_ENV') === 'development';

    // sanitize env values (whitespace is a silent killer)
    this.smtpUser = (this.configService.get<string>('SMTP_USER') || '').trim();
    this.smtpPass = (this.configService.get<string>('SMTP_PASS') || '').replace(/\s/g, '');
    this.smtpHost = (this.configService.get<string>('SMTP_HOST') || 'smtp.gmail.com').trim();
    this.smtpPort = Number(this.configService.get<string>('SMTP_PORT') || '587');

    this.logger.log(`NODE_ENV=${this.configService.get<string>('NODE_ENV') || 'undefined'}`);
    this.logger.log(`SMTP_HOST=${this.smtpHost}`);
    this.logger.log(`SMTP_PORT=${this.smtpPort}`);
    this.logger.log(`SMTP_USER=${this.smtpUser ? 'SET' : 'MISSING'}`);
    this.logger.log(`SMTP_PASS=${this.smtpPass ? 'SET' : 'MISSING'}`);

    if (!this.smtpUser || !this.smtpPass) {
      this.logger.warn('SMTP credentials not configured. Email sending disabled.');
      return;
    }

    // Port rules: 587 => secure false (STARTTLS), 465 => secure true (SSL)
    const secure = this.smtpPort === 465;

    try {
      this.transporter = nodemailer.createTransport({
        host: this.smtpHost,
        port: this.smtpPort,
        secure,
        auth: {
          user: this.smtpUser,
          pass: this.smtpPass,
        },

        // For 587, force STARTTLS properly
        ...(this.smtpPort === 587
          ? {
              requireTLS: true,
              tls: { servername: this.smtpHost },
            }
          : {}),
      });

      // Hard proof that auth works (stops you guessing)
      await this.transporter.verify();
      this.logger.log('✅ SMTP transporter initialized & verified');
    } catch (error: any) {
      this.transporter = null;
      this.logger.error(`❌ SMTP init/verify failed: ${error?.message || error}`);
      this.logger.warn('Email sending will be disabled. In development, codes will be logged.');
    }
  }

  private ensureTransporterOrDevFallback(actionName: string) {
    if (this.transporter) return;

    if (!this.isDevelopment) {
      throw new Error(
        `${actionName} failed: Email service not configured or SMTP verify failed. Check SMTP_* env vars and Gmail App Password.`,
      );
    }
  }

  async sendVerificationEmail(email: string, code: string): Promise<void> {
    const frontend = (this.configService.get<string>('FRONTEND_URL') || 'http://localhost:3000').trim();
    const verificationUrl = `${frontend}/verify-email?token=${encodeURIComponent(code)}`;

    if (this.isDevelopment) {
      this.logger.log('\n' + '='.repeat(80));
      this.logger.log('📧 EMAIL VERIFICATION CODE');
      this.logger.log('='.repeat(80));
      this.logger.log(`Email: ${email}`);
      this.logger.log(`Verification Code: ${code}`);
      this.logger.log(`Verification URL: ${verificationUrl}`);
      this.logger.log('='.repeat(80) + '\n');
    }

    this.ensureTransporterOrDevFallback('sendVerificationEmail');
    if (!this.transporter) return;

    await this.sendMail({
      to: email,
      subject: 'Code de vérification - ODIN Club',
      html: this.verificationTemplate(code, verificationUrl),
    });

    this.logger.log(`✅ Verification email sent to ${email}`);
  }

  async sendPasswordResetEmail(email: string, code: string): Promise<void> {
    const frontend = (this.configService.get<string>('FRONTEND_URL') || 'http://localhost:3000').trim();
    const resetUrl = `${frontend}/reset-password?token=${encodeURIComponent(code)}`;

    if (this.isDevelopment) {
      this.logger.log('\n' + '='.repeat(80));
      this.logger.log('🔑 PASSWORD RESET CODE');
      this.logger.log('='.repeat(80));
      this.logger.log(`Email: ${email}`);
      this.logger.log(`Reset Code: ${code}`);
      this.logger.log(`Reset URL: ${resetUrl}`);
      this.logger.log('='.repeat(80) + '\n');
    }

    this.ensureTransporterOrDevFallback('sendPasswordResetEmail');
    if (!this.transporter) return;

    await this.sendMail({
      to: email,
      subject: 'Code de réinitialisation - ODIN Club',
      html: this.resetTemplate(code, resetUrl),
    });

    this.logger.log(`✅ Password reset email sent to ${email}`);
  }

  private async sendMail(opts: { to: string; subject: string; html: string }) {
    try {
      await this.transporter!.sendMail({
        from: `"ODIN Club" <${this.smtpUser}>`,
        to: opts.to,
        subject: opts.subject,
        html: opts.html,
      });
    } catch (error: any) {
      this.logger.error(`❌ Failed to send email: ${error?.message || error}`);
      if (!this.isDevelopment) throw error;
    }
  }

  private verificationTemplate(code: string, url: string) {
    return `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #4CAF50 0%, #81C784 100%); padding: 30px; border-radius: 10px; text-align: center; margin-bottom: 20px;">
          <h1 style="color: white; margin: 0; font-size: 32px;">ODIN Club</h1>
        </div>
        <h2 style="color: #333; text-align: center;">Bienvenue sur ODIN Club!</h2>
        <p style="color: #666; font-size: 16px; text-align: center;">
          Merci de vous être inscrit. Utilisez le code ci-dessous pour vérifier votre adresse email:
        </p>
        <div style="background-color: #f5f5f5; border: 2px dashed #4CAF50; border-radius: 10px; padding: 30px; text-align: center; margin: 30px 0;">
          <div style="font-size: 48px; font-weight: bold; color: #4CAF50; letter-spacing: 10px; font-family: 'Courier New', monospace;">
            ${code}
          </div>
        </div>
        <p style="color: #666; font-size: 14px; text-align: center;">Ou cliquez sur le lien ci-dessous:</p>
        <div style="text-align: center; margin: 20px 0;">
          <a href="${url}" style="display: inline-block; padding: 12px 24px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 5px;">
            Vérifier mon email
          </a>
        </div>
        <p style="color: #999; font-size: 12px; text-align: center; margin-top: 30px;">
          Ce code expirera dans 24 heures. Si vous n'avez pas créé de compte, ignorez cet email.
        </p>
      </div>
    `;
  }

  private resetTemplate(code: string, url: string) {
    return `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #4CAF50 0%, #81C784 100%); padding: 30px; border-radius: 10px; text-align: center; margin-bottom: 20px;">
          <h1 style="color: white; margin: 0; font-size: 32px;">ODIN Club</h1>
        </div>
        <h2 style="color: #333; text-align: center;">Réinitialisation de mot de passe</h2>
        <p style="color: #666; font-size: 16px; text-align: center;">
          Vous avez demandé à réinitialiser votre mot de passe. Utilisez le code ci-dessous:
        </p>
        <div style="background-color: #f5f5f5; border: 2px dashed #dc3545; border-radius: 10px; padding: 30px; text-align: center; margin: 30px 0;">
          <div style="font-size: 48px; font-weight: bold; color: #dc3545; letter-spacing: 10px; font-family: 'Courier New', monospace;">
            ${code}
          </div>
        </div>
        <p style="color: #666; font-size: 14px; text-align: center;">Ou cliquez sur le lien ci-dessous:</p>
        <div style="text-align: center; margin: 20px 0;">
          <a href="${url}" style="display: inline-block; padding: 12px 24px; background-color: #dc3545; color: white; text-decoration: none; border-radius: 5px;">
            Réinitialiser mon mot de passe
          </a>
        </div>
        <p style="color: #999; font-size: 12px; text-align: center; margin-top: 30px;">
          Ce code expirera dans 1 heure. Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.
        </p>
      </div>
    `;
  }
}
