import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import * as jwt from 'jsonwebtoken';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { MailService } from '../mail/mail.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly config: ConfigService,
    private readonly mailService: MailService,
  ) {}

  async register(dto: RegisterDto) {
    const { email, fullName, password } = dto;

    const existingUser = await this.usersService.findByEmail(email);
    if (existingUser) {
      throw new BadRequestException('User already exists');
    }

    const saltRounds =
      Number(this.config.get<string>('SALT_ROUNDS', '10')) || 10;

    const hashedPassword = await bcrypt.hash(password, saltRounds);

    const newUser = await this.usersService.create({
      email,
      fullName,
      password: hashedPassword,
      
    });

    await this.usersService.update(newUser.id, {
    isEmailVerified: false,
    });

    try {
      await this.sendVerificationEmail(newUser.id, newUser.email);
    } catch (error) {
      await this.usersService.delete(newUser.id);
      throw new ServiceUnavailableException(
        'Email delivery is not configured correctly. Please try again later.',
      );
    }

    return {
      message: 'User registered. Please verify your email.',
      user: {
        id: newUser.id,
        email: newUser.email,
        fullName: newUser.fullName,
      },
    };
  }

  async login(dto: LoginDto) {
    const { email, password } = dto;

    const user = await this.usersService.findByEmail(email);
    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    if (!user.isEmailVerified) {
      throw new UnauthorizedException('Please verify your email first');
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const secret = this.config.get<string>('JWT_SECRET');
    if (!secret) {
      throw new Error('JWT_SECRET is not set');
    }

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      secret,
      { expiresIn: '15m' },
    );

    return {
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
      },
    };
  }

  async verifyEmail(token: string) {
    try {
      const emailSecret = this.config.get<string>('JWT_EMAIL_SECRET');
      if (!emailSecret) {
        throw new Error('JWT_EMAIL_SECRET is not set');
      }

      const payload = jwt.verify(token, emailSecret) as {
        userId: number;
        email: string;
        type: string;
      };

      if (payload.type !== 'verify-email') {
        throw new BadRequestException('Invalid token');
      }

      const user = await this.usersService.findByEmail(payload.email);
      if (!user) {
        throw new BadRequestException('User not found');
      }

      user.isEmailVerified = true;
      await this.usersService.save(user);

      return { message: 'Email verified successfully' };
    } catch {
      throw new BadRequestException('Invalid or expired token');
    }
  }

  async resendVerificationEmail(email: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      throw new BadRequestException('User not found');
    }

    if (user.isEmailVerified) {
      throw new BadRequestException('Email is already verified');
    }

    try {
      await this.sendVerificationEmail(user.id, user.email);
    } catch {
      throw new ServiceUnavailableException(
        'Email delivery is not configured correctly. Please try again later.',
      );
    }

    return { message: 'Verification email sent successfully' };
  }

  private async sendVerificationEmail(userId: number, email: string) {
    const emailSecret = this.config.get<string>('JWT_EMAIL_SECRET');
    if (!emailSecret) {
      throw new Error('JWT_EMAIL_SECRET is not set');
    }

    const verifyToken = jwt.sign(
      { userId, email, type: 'verify-email' },
      emailSecret,
      { expiresIn: '1d' },
    );

    await this.mailService.sendVerificationEmail(email, verifyToken);
  }
}
