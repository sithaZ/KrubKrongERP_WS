import {
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

  @Roles(Role.ADMIN)
  @Get()
  async findAll(@Query('role') role?: string) {
    const users = await this.usersService.findAll(role);
    return users.map(user => {
      const userObj = user.toObject ? user.toObject() : user;
      
      const { password, _id, ...safeUser } = userObj as any;
      
      
      return { id: _id.toString(), ...safeUser };
    });
  }

  @Roles(Role.ADMIN)
  @Get(':id')
  async findOne(@Param('id') id: string) {
    const user = await this.usersService.findOne(id);
    const userObj = user.toObject ? user.toObject() : user;
    const { password, _id, ...safeUser } = userObj as any;
    
    return { id: _id.toString(), ...safeUser };
  }

  @Roles(Role.ADMIN)
  @Post()
  create(@Body() userData: any) {
    return this.usersService.create(userData);
  }

  @Roles(Role.ADMIN)
  @Put(':id')
  update(@Param('id') id: string, @Body() updateData: any) {
    return this.usersService.update(id, updateData);
  }

  @Roles(Role.ADMIN)
  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }
}
