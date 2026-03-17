import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService
  ) {}

  async register(username: string, pass: string) {
    return this.usersService.create({
      username: username,
      password: pass,
    });
  }
  async login(username: string, pass: string) {
    
    const user = await this.usersService.findOneByUsername(username);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }
    
    if (user.isActive === false) {
      throw new UnauthorizedException('This account has been deactivated. Please contact the administrator.');
    }
    
    const isMatch = await bcrypt.compare(pass, user.password);
    if (!isMatch) {
      throw new UnauthorizedException('Invalid credentials');
    }

    
    const payload = { sub: user.id, username: user.username };
    return {
      access_token: await this.jwtService.signAsync(payload),
      role: user.role,
    };
  }
}