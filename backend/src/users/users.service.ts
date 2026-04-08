import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from './user.entity';
import { EventsGateway } from '../events/events.gateway'; // 1. Import the WebSocket Gateway

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
    private eventsGateway: EventsGateway // 2. Inject the Gateway into the constructor
  ) {}

  async findAll(): Promise<User[]> {
    return this.userModel.find().exec();
  }

  async findOne(id: string): Promise<User> {
    const user = await this.userModel.findById(id).exec();
    if (!user) throw new NotFoundException(`User with ID ${id} not found`);
    return user;
  }
  
  async findByEmail(email: string): Promise<User | null> {
    return this.userModel.findOne({ email }).exec();
  }

  async findOneByUsername(username: string): Promise<User | null> {
    return this.userModel.findOne({ username }).exec();
  }

  async create(userData: any): Promise<User> {
    const newUser = new this.userModel(userData);
    return newUser.save();
  }

 async update(id: string, updateData: any): Promise<User> {
    const updatedUser = await this.userModel
      
      .findByIdAndUpdate(id, updateData, { returnDocument: 'after' }) 
      .exec();
      
    if (!updatedUser) throw new NotFoundException(`User with ID ${id} not found`);

 
    if (updateData.role) {
      this.eventsGateway.notifyRoleChange(id, updatedUser.role);
    }

    return updatedUser;
  }

  async remove(id: string): Promise<void> {
    const result = await this.userModel.findByIdAndDelete(id).exec();
    if (!result) throw new NotFoundException(`User with ID ${id} not found`);
  }
}