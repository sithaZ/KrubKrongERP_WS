import { Body, Controller, Post, Get, Put, HttpCode, HttpStatus, UseGuards, Request } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthGuard } from './auth.guard';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @HttpCode(HttpStatus.OK)
  @Post('login')
  signIn(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto.email, loginDto.password);
  }

  @Post('register')
  register(@Body() registerDto: RegisterDto) {
    return this.authService.register(registerDto);
  }

  @Post('register-admin')
  registerAdmin(@Body() registerDto: RegisterDto) {
    return this.authService.registerAdmin(registerDto);
  }

  @UseGuards(AuthGuard)
  @Get('me')
  getCurrentUser(@Request() req: any) {
    return this.authService.getCurrentUser(req.user.userId);
  }

  @UseGuards(AuthGuard)
  @Put('profile')
  updateProfile(@Request() req: any, @Body() body: { name?: string; phone?: string; password?: string }) {
    return this.authService.updateProfile(req.user.userId, body);
  }
}
