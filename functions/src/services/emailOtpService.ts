import * as nodemailer from 'nodemailer';
import type { Transporter } from 'nodemailer';
import { environment } from '../config/environment';

export interface SendOtpResult {
  success: boolean;
  message: string;
  error?: string;
}

export class EmailOtpService {
  private static transporter: Transporter | null = null;

  private static getTransporter(): Transporter | null {
    if (this.transporter) return this.transporter;

    const user = process.env.SMTP_EMAIL || environment.smtp?.user;
    const pass = process.env.SMTP_APP_PASSWORD || environment.smtp?.pass;

    if (!user || !pass) {
      return null;
    }

    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user,
        pass, // 16-character Google App Password
      },
    });

    return this.transporter;
  }

  /**
   * Sends 6-digit OTP verification email directly to recipient inbox
   */
  public static async sendOtpEmail(email: string, otp: string, recipientName: string = 'User'): Promise<SendOtpResult> {
    const transporter = this.getTransporter();

    if (!transporter) {
      console.warn('[EmailOtpService] SMTP credentials not set. Simulating OTP dispatch.');
      return {
        success: true,
        message: 'SMTP credentials pending in .env. OTP generated in demo mode.',
      };
    }

    try {
      const mailOptions = {
        from: `"My Roomy Verification" <${process.env.SMTP_EMAIL || environment.smtp?.user}>`,
        to: email,
        subject: `Your My Roomy Verification Code is ${otp}`,
        html: `
          <div style="font-family: Arial, sans-serif; background-color: #171329; color: #FFFFFF; padding: 32px; border-radius: 12px; max-width: 500px; margin: auto;">
            <h1 style="color: #B8A1FF; font-size: 26px; margin-bottom: 8px;">My Roomy</h1>
            <p style="color: #C4BDD6; font-size: 14px; margin-top: 0;">Direct verified room stays. Zero brokerage.</p>
            <hr style="border: none; border-top: 1px solid rgba(255,255,255,0.1); margin: 20px 0;" />
            <p style="font-size: 16px; color: #FFFFFF;">Hello <strong>${recipientName}</strong>,</p>
            <p style="font-size: 14px; color: #C4BDD6;">Use the 6-digit verification code below to verify your email and activate your account on My Roomy:</p>
            <div style="background-color: #27213D; border: 1.5px solid #B8A1FF; border-radius: 10px; padding: 18px; text-align: center; margin: 24px 0;">
              <span style="font-size: 32px; letter-spacing: 10px; font-weight: bold; color: #B8A1FF;">${otp}</span>
            </div>
            <p style="font-size: 13px; color: #C4BDD6;">This code is valid for <strong>10 minutes</strong>. If you did not request this, you can safely ignore this email.</p>
            <hr style="border: none; border-top: 1px solid rgba(255,255,255,0.1); margin: 20px 0;" />
            <p style="font-size: 11px; color: #8E8A9E; text-align: center;">&copy; 2026 My Roomy. All rights reserved.</p>
          </div>
        `,
      };

      await transporter.sendMail(mailOptions);
      return {
        success: true,
        message: `Verification code successfully sent to ${email}`,
      };
    } catch (err: any) {
      console.error('[EmailOtpService] Failed to send email:', err);
      return {
        success: false,
        message: 'Could not send verification email.',
        error: err.message,
      };
    }
  }
}
