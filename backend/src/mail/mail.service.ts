import { Injectable, Logger } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  private transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  async sendEmployeeCredentials(data: {
    to: string;
    fullName: string;
    username: string;
    temporaryPassword: string;
  }) {
    await this.transporter.sendMail({
      from: process.env.SMTP_FROM,
      to: data.to,
      subject: 'Your KrubKrong ERP Employee Account',
      html: `
        <h2>Welcome to KrubKrong ERP</h2>
        <p>Hello ${data.fullName},</p>
        <p>Your employee account has been created.</p>
        <p><strong>Username:</strong> ${data.username}</p>
        <p><strong>Temporary Password:</strong> ${data.temporaryPassword}</p>
        <p>Please change your password after first login.</p>
        <p>KrubKrong ERP Team</p>
      `,
    });

    this.logger.log(`Credentials email sent to ${data.to}`);
  }
}