import {
  BadRequestException,
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { AuthGuard } from '../auth/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';

@Controller('users')
@UseGuards(AuthGuard, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  private sanitizeUser(user: any) {
    const userObj = user?.toObject ? user.toObject() : user;
    const { password, _id, ...safeUser } = userObj as any;
    return { id: _id.toString(), ...safeUser };
  }

  @Roles(Role.ADMIN)
  @Get()
  async findAll(@Query('role') role?: string) {
    const users = await this.usersService.findAll(role);
    return users.map((user) => this.sanitizeUser(user));
  }

  @Roles(Role.ADMIN)
  @Get(':id')
  async findOne(@Param('id') id: string) {
    const user = await this.usersService.findOne(id);
    return this.sanitizeUser(user);
  }

  @Roles(Role.ADMIN)
  @Post()
  async create(@Body() userData: any) {
    const user = await this.usersService.create(userData);
    return this.sanitizeUser(user);
  }

  @Roles(Role.ADMIN)
  @Put(':id')
  async update(@Param('id') id: string, @Body() updateData: any) {
    const user = await this.usersService.update(id, updateData);
    return this.sanitizeUser(user);
  }

  @Roles(Role.ADMIN)
  @Post(':id/reset-manager-password')
  resetManagerPassword(@Param('id') id: string) {
    return this.usersService.resetManagerPassword(id);
  }

  @Roles(Role.ADMIN)
  @Delete(':id')
  remove(
    @Param('id') id: string,
    @Query('hardDelete') hardDelete?: string,
  ) {
    const shouldHardDelete =
      typeof hardDelete === 'string' &&
      ['1', 'true', 'yes'].includes(hardDelete.toLowerCase());

    if (shouldHardDelete) {
      return this.usersService.remove(id, { hardDelete: true });
    }

    return this.usersService.remove(id);
  }

  @Roles(Role.ADMIN)
  @Put(':id/assign-shop')
  async assignShop(@Param('id') id: string, @Body('shopId') shopId?: string) {
    if (!shopId) {
      throw new BadRequestException('shopId is required');
    }

    const user = await this.usersService.assignManagerToShop(id, shopId);
    return this.sanitizeUser(user);
  }
}
