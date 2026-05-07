import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Role } from '../common/enums/role.enum';
import { normalizeRole } from '../common/utils/role.utils';
import { EventsGateway } from '../events/events.gateway';
import { User } from './user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
    private eventsGateway: EventsGateway,
  ) {}

  async findAll(role?: string): Promise<User[]> {
    const query: any = {};

    if (role) {
      const normalizedRole = normalizeRole(role);

      const roleValues = [
        role,
        role.toLowerCase(),
        normalizedRole,
      ].filter((value): value is string => Boolean(value));

      query.role = { $in: roleValues };
    }

    return this.userModel.find(query).sort({ createdAt: -1 }).exec();
  }

  async findManagers(): Promise<User[]> {
    return this.userModel
      .find({ role: Role.MANAGER })
      .sort({ createdAt: -1 })
      .exec();
  }

  async findOne(id: string): Promise<User> {
    const user = await this.userModel.findById(id).exec();

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return user;
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.userModel.findOne({ email }).exec();
  }

  async findOneByUsername(username: string): Promise<User | null> {
    return this.userModel.findOne({ username }).exec();
  }

  async create(userData: Partial<User>): Promise<User> {
    const newUser = new this.userModel(userData);
    return newUser.save();
  }

  async update(id: string, updateData: Partial<User>): Promise<User> {
    const updatedUser = await this.userModel
      .findByIdAndUpdate(id, updateData, { returnDocument: 'after' })
      .exec();

    if (!updatedUser) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    if (updateData.role) {
      this.eventsGateway.notifyRoleChange(id, updatedUser.role);
    }

    return updatedUser;
  }

  async remove(id: string): Promise<void> {
    const result = await this.userModel.findByIdAndDelete(id).exec();

    if (!result) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
  }
}