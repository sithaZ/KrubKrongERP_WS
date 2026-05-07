import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { normalizeRole } from '../common/utils/role.utils';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET') || 'secretKey',
    });
  }

  async validate(payload: any) {
    const userId = payload.userId || payload.sub;

    return {
      sub: userId,
      userId,
      username: payload.username,
      role: normalizeRole(payload.role) || payload.role,
      companyId: payload.companyId || payload.shopId || null,
      shopId: payload.shopId || payload.companyId || null,
    };
  }
}
