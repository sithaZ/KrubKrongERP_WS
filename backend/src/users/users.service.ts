import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';
import { Role } from '../common/enums/role.enum';
import { normalizeRole } from '../common/utils/role.utils';
import { EventsGateway } from '../events/events.gateway';
import { User } from './user.entity';
import { Company } from '../companies/company.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
    @InjectModel(Company.name) private companyModel: Model<Company>,
    private eventsGateway: EventsGateway,
  ) {}

  private assertManagerRole(role?: string) {
    if (normalizeRole(role) !== Role.MANAGER) {
      throw new ForbiddenException(
        'ADMIN can only create or manage manager accounts through /users',
      );
    }
  }

  private async assertManagerTarget(id: string) {
    const user = await this.findOne(id);

    if (normalizeRole(user.role) !== Role.MANAGER) {
      throw new ForbiddenException(
        'ADMIN cannot directly manage employee accounts through /users',
      );
    }

    return user;
  }

  async findAll(role?: string): Promise<User[]> {
    const query: any = {};

    if (role) {
      const normalizedRole = normalizeRole(role);

      const roleValues = [role, role.toLowerCase(), normalizedRole].filter(
        (value): value is string => Boolean(value),
      );

      query.role = { $in: roleValues };
    }

    return this.userModel
      .find(query)
      .populate('companyId', 'shopName status')
      .sort({ createdAt: -1 })
      .exec();
  }

  async findManagers(): Promise<User[]> {
    return this.userModel
      .find({ role: Role.MANAGER })
      .sort({ createdAt: -1 })
      .exec();
  }

  async findOne(id: string): Promise<User> {
    const user = await this.userModel
      .findById(id)
      .populate('companyId', 'shopName status')
      .exec();

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return user;
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.userModel.findOne({ email: email.trim().toLowerCase() }).exec();
  }

  async findOneByUsername(username: string): Promise<User | null> {
    return this.userModel.findOne({ username }).exec();
  }

  async create(userData: Partial<User>): Promise<User> {
    this.assertManagerRole(userData.role);

    const email = userData.email?.trim().toLowerCase();
    const username = userData.username?.trim().toLowerCase();
    const temporaryPassword =
      (userData as any).temporaryPassword || userData.password;

    if (!email || !username || !userData.name || !temporaryPassword) {
      throw new BadRequestException(
        'name, email, username, and temporaryPassword are required',
      );
    }

    if (await this.userModel.findOne({ email }).exec()) {
      throw new ConflictException('Email already exists');
    }

    if (await this.userModel.findOne({ username }).exec()) {
      throw new ConflictException('Username already exists');
    }

    const hashedPassword = await bcrypt.hash(temporaryPassword, 10);

    const newUser = new this.userModel({
      ...userData,
      email,
      username,
      password: hashedPassword,
      role: Role.MANAGER,
    });

    return newUser.save();
  }

  async createEmployeeAccount(userData: Partial<User>): Promise<User> {
    const newUser = new this.userModel(userData);
    return newUser.save();
  }

  async createAdminAccount(userData: Partial<User>): Promise<User> {
    const email = userData.email?.trim().toLowerCase();
    const username = userData.username?.trim().toLowerCase();
    const password = userData.password;

    if (!email || !username || !userData.name || !password) {
      throw new BadRequestException(
        'name, email, username, and password are required',
      );
    }

    if (await this.userModel.findOne({ email }).exec()) {
      throw new ConflictException('Email already exists');
    }

    if (await this.userModel.findOne({ username }).exec()) {
      throw new ConflictException('Username already exists');
    }

    const newUser = new this.userModel({
      ...userData,
      email,
      username,
      role: Role.ADMIN,
      isActive: true,
    });

    return newUser.save();
  }

  async update(id: string, updateData: Partial<User>): Promise<User> {
    await this.assertManagerTarget(id);

    if (updateData.role && normalizeRole(updateData.role) !== Role.MANAGER) {
      throw new ForbiddenException('Manager accounts must remain MANAGER role');
    }

    if ((updateData as any).companyId || (updateData as any).shopId) {
      throw new ForbiddenException(
        'Assign managers to shops through the shop assignment flow only',
      );
    }

    if (updateData.password) {
      throw new ForbiddenException(
        'Reset manager passwords through the reset password flow only',
      );
    }

    if (updateData.email) {
      updateData.email = updateData.email.trim().toLowerCase();
      const existingEmail = await this.userModel.findOne({
        email: updateData.email,
      });
      if (existingEmail && existingEmail._id.toString() !== id) {
        throw new ConflictException('Email already exists');
      }
    }

    if (updateData.username) {
      updateData.username = updateData.username.trim().toLowerCase();
      const existingUsername = await this.userModel.findOne({
        username: updateData.username,
      });
      if (existingUsername && existingUsername._id.toString() !== id) {
        throw new ConflictException('Username already exists');
      }
    }

    const updatedUser = await this.userModel
      .findByIdAndUpdate(id, updateData, { returnDocument: 'after' })
      .populate('companyId', 'shopName status')
      .exec();

    if (!updatedUser) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    if (updateData.role) {
      this.eventsGateway.notifyRoleChange(id, updatedUser.role);
    }

    return updatedUser;
  }

  async updateEmployeeAccount(
    id: string,
    updateData: Partial<User>,
  ): Promise<User> {
    const updatedUser = await this.userModel
      .findByIdAndUpdate(id, updateData, { returnDocument: 'after' })
      .exec();

    if (!updatedUser) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return updatedUser;
  }

  async remove(
    id: string,
    options?: { hardDelete?: boolean },
  ): Promise<void | { success: true; deactivated: boolean }> {
    const manager = await this.assertManagerTarget(id);

    if (options?.hardDelete) {
      await this.companyModel.updateMany(
        { managerId: manager._id },
        { $unset: { managerId: 1 } },
      );

      const result = await this.userModel.findByIdAndDelete(id).exec();

      if (!result) {
        throw new NotFoundException(`User with ID ${id} not found`);
      }

      return;
    }

    manager.isActive = false;
    await manager.save();

    return {
      success: true,
      deactivated: true,
    };
  }

  async removeEmployeeAccount(id: string): Promise<void> {
    const result = await this.userModel.findByIdAndDelete(id).exec();

    if (!result) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
  }

  async resetManagerPassword(id: string) {
    const manager = await this.assertManagerTarget(id);
    const temporaryPassword = `MGR-${randomBytes(4).toString('hex')}`;

    manager.password = await bcrypt.hash(temporaryPassword, 10);
    await manager.save();

    return {
      id: manager._id.toString(),
      username: manager.username,
      email: manager.email,
      temporaryPassword,
    };
  }

  async assignManagerToShop(id: string, shopId: string) {
    const manager = await this.assertManagerTarget(id);

    if (!Types.ObjectId.isValid(shopId)) {
      throw new BadRequestException('Invalid shop ID');
    }

    const shop = await this.companyModel.findById(shopId).exec();

    if (!shop) {
      throw new NotFoundException('Shop not found');
    }

    const previousManagerId = manager.companyId?.toString();

    if (previousManagerId && previousManagerId !== shopId) {
      await this.companyModel.updateOne(
        { _id: new Types.ObjectId(previousManagerId), managerId: manager._id },
        { $unset: { managerId: 1 } },
      );
    }

    if (
      shop.managerId &&
      shop.managerId.toString() !== manager._id.toString()
    ) {
      await this.userModel.findByIdAndUpdate(shop.managerId, {
        $unset: { companyId: 1 },
      });
    }

    await this.companyModel.updateMany(
      { managerId: manager._id, _id: { $ne: shop._id } },
      { $unset: { managerId: 1 } },
    );

    shop.managerId = manager._id as Types.ObjectId;
    await shop.save();

    manager.companyId = shop._id as Types.ObjectId;
    manager.isActive = manager.isActive ?? true;
    await manager.save();

    return this.findOne(id);
  }
}
