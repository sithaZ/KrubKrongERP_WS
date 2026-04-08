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

  async register(userData: any) {
    
    const salt = await bcrypt.genSalt(10);
    userData.password = await bcrypt.hash(userData.password, salt);
    
    const user = await this.usersService.create(userData);
    const userObj = user.toObject ? user.toObject() : user;
    const { password, ...safeUser } = userObj as any;
    return safeUser;
  }

  async login(username: string, pass: string) {
    const user = await this.usersService.findOneByUsername(username);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }
    
    const isMatch = await bcrypt.compare(pass, user.password);
    if (!isMatch) {
      throw new UnauthorizedException('Invalid credentials');
    }
    
    
    const payload = { 
      sub: user._id.toString(), 
      username: user.username,
      role: user.role 
    };
    
    return {
      access_token: await this.jwtService.signAsync(payload),
    };
  }
}