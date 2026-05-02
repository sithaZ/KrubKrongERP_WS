import { Injectable, UnauthorizedException, NotFoundException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
<<<<<<< HEAD
import { RegisterDto } from './dto/register.dto';
=======
>>>>>>> 90061212bc30cab3665bd0cf20465d9da5a273ef

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService
  ) {}

<<<<<<< HEAD
  async register(registerDto: RegisterDto) {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(registerDto.password, salt);

    const userData = {
      username: registerDto.email.split('@')[0],
      email: registerDto.email,
      password: hashedPassword,
      name: registerDto.name,
      phone: registerDto.phone,
    };
=======
  async register(userData: any) {
    const salt = await bcrypt.genSalt(10);
    userData.password = await bcrypt.hash(userData.password, salt);
>>>>>>> 90061212bc30cab3665bd0cf20465d9da5a273ef

    const user = await this.usersService.create(userData);

    const token = await this.jwtService.signAsync({
      sub: user._id.toString(),
      email: user.email,
      role: user.role
    });

    return {
      token,
      refreshToken: token,
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        role: user.role,
        avatar: user.avatar || null,
        phone: user.phone || null,
        isActive: user.isActive,
      },
    };
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

<<<<<<< HEAD
    const token = await this.jwtService.signAsync({
      sub: user._id.toString(),
      email: user.email,
      role: user.role
    });

    return {
      token,
      refreshToken: token,
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        role: user.role,
        avatar: user.avatar || null,
        phone: user.phone || null,
        isActive: user.isActive,
      },
    };
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
    };
  }
}

=======
    const payload = {
      sub: user._id.toString(),
      username: user.username,
      role: user.role,
    };

    return {
      access_token: await this.jwtService.signAsync(payload),
      role: user.role,
      username: user.username,
    };
  }
}
>>>>>>> 90061212bc30cab3665bd0cf20465d9da5a273ef
