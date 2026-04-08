import { Controller, Get, Post, Put, Delete, Body, Param } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  async findAll() {
    const users = await this.usersService.findAll();
    return users.map(user => {
      const userObj = user.toObject ? user.toObject() : user;
      
      const { password, _id, ...safeUser } = userObj as any;
      
      
      return { id: _id.toString(), ...safeUser };
    });
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    const user = await this.usersService.findOne(id);
    const userObj = user.toObject ? user.toObject() : user;
    const { password, _id, ...safeUser } = userObj as any;
    
    return { id: _id.toString(), ...safeUser };
  }

  @Post()
  create(@Body() userData: any) {
    return this.usersService.create(userData);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateData: any) {
    return this.usersService.update(id, updateData);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }
}