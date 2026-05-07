import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as bcrypt from 'bcrypt';

import { Company } from './company.entity';
import { User } from '../users/user.entity';
import { Role } from '../common/enums/role.enum';

@Injectable()
export class CompaniesService {
  constructor(
    @InjectModel(Company.name)
    private readonly companyModel: Model<Company>,

    @InjectModel(User.name)
    private readonly userModel: Model<User>,
  ) {}

  async create(createCompanyDto: any, adminUser?: any) {
    const company = await this.companyModel.create({
      shopName: createCompanyDto.shopName,
      ownerName: createCompanyDto.ownerName,
      ownerEmail: createCompanyDto.ownerEmail,
      phone: createCompanyDto.phone || '',
      address: createCompanyDto.address || '',
      businessType: createCompanyDto.businessType || 'General',
      status: createCompanyDto.status || 'active',
      isActive: createCompanyDto.status !== 'inactive',
      createdByAdminId: adminUser?.userId
        ? new Types.ObjectId(adminUser.userId)
        : undefined,
    });

    return this.companyModel
      .findById(company._id)
      .populate('managerId', 'name email phone role')
      .exec();
  }

  async findAll() {
    return this.companyModel
      .find()
      .populate('managerId', 'name email phone role')
      .sort({ createdAt: -1 })
      .exec();
  }

  async findOne(id: string) {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('Invalid shop ID');
    }

    const company = await this.companyModel
      .findById(id)
      .populate('managerId', 'name email phone role')
      .exec();

    if (!company) {
      throw new NotFoundException('Shop not found');
    }

    return company;
  }

  async update(id: string, updateCompanyDto: any) {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('Invalid shop ID');
    }

    const updateData = {
      ...updateCompanyDto,
      isActive:
        updateCompanyDto.status === 'inactive'
          ? false
          : updateCompanyDto.status === 'active'
            ? true
            : undefined,
    };

    Object.keys(updateData).forEach((key) => {
      if (updateData[key] === undefined) {
        delete updateData[key];
      }
    });

    const company = await this.companyModel
      .findByIdAndUpdate(id, updateData, { new: true })
      .populate('managerId', 'name email phone role')
      .exec();

    if (!company) {
      throw new NotFoundException('Shop not found');
    }

    return company;
  }

 async assignManager(companyId: string, managerId: string) {
  const company = await this.companyModel.findById(companyId);

  if (!company) {
    throw new NotFoundException('Shop not found');
  }

  const manager = await this.userModel.findById(managerId);

  if (!manager) {
    throw new NotFoundException('Manager not found');
  }

  manager.companyId = company._id as Types.ObjectId;
  manager.role = Role.MANAGER;
  await manager.save();

 await this.companyModel.findByIdAndUpdate(
  companyId,
  { managerId: new Types.ObjectId(managerId) },
  { new: true, runValidators: false },
);

  return this.companyModel
    .findById(companyId)
    .populate('managerId', 'name email phone role')
    .exec();
}

  async createManager(companyId: string, managerDto: any) {
    if (!Types.ObjectId.isValid(companyId)) {
      throw new BadRequestException('Invalid shop ID');
    }

    const company = await this.companyModel.findById(companyId).exec();

    if (!company) {
      throw new NotFoundException('Shop not found');
    }

    const existingUser = await this.userModel
      .findOne({ email: managerDto.email })
      .exec();

    if (existingUser) {
      existingUser.role = Role.MANAGER;
      existingUser.companyId = company._id as Types.ObjectId;
      existingUser.name = managerDto.name || existingUser.name;
      existingUser.phone = managerDto.phone || existingUser.phone;
      await existingUser.save();

      company.managerId = existingUser._id as Types.ObjectId;
      await company.save();

      return this.companyModel
        .findById(companyId)
        .populate('managerId', 'name email phone role')
        .exec();
    }

    const hashedPassword = await bcrypt.hash(managerDto.password, 10);

    const manager = await this.userModel.create({
      username: managerDto.email.split('@')[0],
      email: managerDto.email,
      password: hashedPassword,
      name: managerDto.name,
      phone: managerDto.phone || '',
      role: Role.MANAGER,
      companyId: company._id,
      isActive: true,
    });

    company.managerId = manager._id as Types.ObjectId;
    await company.save();

    return this.companyModel
      .findById(companyId)
      .populate('managerId', 'name email phone role')
      .exec();
  }

  async remove(id: string) {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('Invalid shop ID');
    }

    const deletedCompany = await this.companyModel.findByIdAndDelete(id).exec();

    if (!deletedCompany) {
      throw new NotFoundException('Shop not found');
    }

    return { message: 'Shop deleted successfully' };
  }
}