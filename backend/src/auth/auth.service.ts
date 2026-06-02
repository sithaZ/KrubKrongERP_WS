import { Injectable, UnauthorizedException, NotFoundException, BadRequestException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { RegisterDto } from './dto/register.dto';
import { normalizeRole } from '../common/utils/role.utils';
import { Role } from '../common/enums/role.enum';
import { Types } from 'mongoose';
@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService
  ) {}

  private buildAuthResponse(user: any, token: string) {
    return {
      token,
      access_token: token,
      refreshToken: token,
      role: user.role,
      username: user.username,
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        role: user.role,
        avatar: user.avatar || null,
        phone: user.phone || null,
        isActive: user.isActive,
        companyId: user.companyId ? user.companyId.toString() : null,
        shopId: user.companyId ? user.companyId.toString() : null,
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
  companyId: registerDto.companyId
    ? new Types.ObjectId(registerDto.companyId)
    : undefined,
};

    const user = await this.usersService.create(userData);
    const normalizedRole = normalizeRole(user.role) || user.role;

    const token = await this.jwtService.signAsync({
      sub: user._id.toString(),
      userId: user._id.toString(),
      email: user.email,
      role: normalizedRole,
      companyId: user.companyId ? user.companyId.toString() : null,
      shopId: user.companyId ? user.companyId.toString() : null,
    });

    return this.buildAuthResponse(user, token);
  }

  async registerAdmin(registerDto: RegisterDto) {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(registerDto.password, salt);

    const userData = {
      username: registerDto.email.split('@')[0],
      email: registerDto.email,
      password: hashedPassword,
      name: registerDto.name,
      phone: registerDto.phone,
      role: Role.ADMIN,
      isActive: true,
    };

    const user = await this.usersService.createAdminAccount(userData);

    const token = await this.jwtService.signAsync({
      sub: user._id.toString(),
      userId: user._id.toString(),
      email: user.email,
      role: Role.ADMIN,
      companyId: null,
      shopId: null,
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
      shopId: user.companyId ? user.companyId.toString() : null,
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
      role: user.role,
      avatar: user.avatar || null,
      phone: user.phone || null,
      isActive: user.isActive,
      companyId: user.companyId ? user.companyId.toString() : null,
      shopId: user.companyId ? user.companyId.toString() : null,
    };
  }

  async updateProfile(userId: string, dto: { name?: string; phone?: string; password?: string; currentPassword?: string }) {
    const user = await this.usersService.findOne(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const updates: any = {};
    if (dto.name) updates.name = dto.name;
    if (dto.phone !== undefined) updates.phone = dto.phone;

    if (dto.password) {
      if (!dto.currentPassword) {
        throw new BadRequestException('Current password is required to set a new password');
      }

      const isMatch = await bcrypt.compare(dto.currentPassword, user.password);
      if (!isMatch) {
        throw new UnauthorizedException('Incorrect current password');
      }

      const salt = await bcrypt.genSalt(10);
      updates.password = await bcrypt.hash(dto.password, salt);
    }

    const updatedUser = await this.usersService.updateEmployeeAccount(userId, updates);

    return {
      id: updatedUser._id.toString(),
      name: updatedUser.name,
      email: updatedUser.email,
      role: updatedUser.role,
      avatar: updatedUser.avatar || null,
      phone: updatedUser.phone || null,
      isActive: updatedUser.isActive,
      companyId: updatedUser.companyId ? updatedUser.companyId.toString() : null,
      shopId: updatedUser.companyId ? updatedUser.companyId.toString() : null,
    };
  }
}
