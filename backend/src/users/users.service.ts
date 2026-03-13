import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async create(userData: Partial<User>): Promise<User> {
    const saltRounds = 10;
    if (userData.password) {
      userData.password = await bcrypt.hash(userData.password, saltRounds);
    }
    
    const newUser = this.usersRepository.create(userData);
    return this.usersRepository.save(newUser);
  }
  async update(id: string, updateData: Partial<User>): Promise<User | null> {
    if (updateData.password) {
      const saltRounds = 10;
      updateData.password = await bcrypt.hash(updateData.password, saltRounds);
    }
    await this.usersRepository.update(id, updateData);
    return this.usersRepository.findOne({ where: { id } });
  }

  // Get all users
  findAll(): Promise<User[]> {
    return this.usersRepository.find();
  }

 
  findOneByUsername(username: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { username } });
  }

  // Delete a user
  async remove(id: string): Promise<void> {
    await this.usersRepository.delete(id);
  }
}