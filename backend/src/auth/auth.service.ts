import { Injectable, UnauthorizedException, NotFoundException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { RegisterDto } from './dto/register.dto';
import { normalizeRole } from '../common/utils/role.utils';
import { Role } from '../common/enums/role.enum';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService
  ) {}

  private buildAuthResponse(user: any, token: string) {
    const normalizedRole = normalizeRole(user.role) || user.role;

    return {
      token,
      access_token: token,
      refreshToken: token,
      role: normalizedRole,
      username: user.username,
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        role: normalizedRole,
        avatar: user.avatar || null,
        phone: user.phone || null,
        isActive: user.isActive,
        companyId: user.companyId ? user.companyId.toString() : null,
      },
    };
  }

  async register(registerDto: RegisterDto) {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(registerDto.password, salt);

    const userData = {
      username: registerDto.email.split('@')[0],
      email: registerDto.email,
      password: hashedPassword,
      name: registerDto.name,
      phone: registerDto.phone,
      role: normalizeRole(registerDto.role) || Role.EMPLOYEE,
      companyId: registerDto.companyId,
    };

    const user = await this.usersService.create(userData);
    const normalizedRole = normalizeRole(user.role) || user.role;

    const token = await this.jwtService.signAsync({
      sub: user._id.toString(),
      userId: user._id.toString(),
      email: user.email,
      role: normalizedRole,
      companyId: user.companyId ? user.companyId.toString() : null,
    });

    return this.buildAuthResponse(user, token);
  }

  async login(email: string, password: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const normalizedRole = normalizeRole(user.role) || user.role;

    const token = await this.jwtService.signAsync({
      sub: user._id.toString(),
      userId: user._id.toString(),
      email: user.email,
      role: normalizedRole,
      companyId: user.companyId ? user.companyId.toString() : null,
    });

    return this.buildAuthResponse(user, token);
  }

  async getCurrentUser(userId: string) {
    const user = await this.usersService.findOne(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    return {
      id: user._id.toString(),
      name: user.name,
      email: user.email,
      role: normalizeRole(user.role) || user.role,
      avatar: user.avatar || null,
      phone: user.phone || null,
      isActive: user.isActive,
      companyId: user.companyId ? user.companyId.toString() : null,
    };
  }
}
