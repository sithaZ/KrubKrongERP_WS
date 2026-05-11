import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';

import { Company } from './company.entity';
import { User } from '../users/user.entity';
import { Role } from '../common/enums/role.enum';
import { normalizeRole } from '../common/utils/role.utils';

@Injectable()
export class CompaniesService {
  private readonly managerPopulateFields =
    'name email phone username role isActive companyId';

  constructor(
    @InjectModel(Company.name)
    private readonly companyModel: Model<Company>,

    @InjectModel(User.name)
    private readonly userModel: Model<User>,
  ) {}

  private sanitizeManager(manager: User | null) {
    if (!manager) {
      return null;
    }

    return {
      id: manager._id.toString(),
      name: manager.name,
      email: manager.email,
      phone: manager.phone || '',
      username: manager.username,
      role: manager.role,
      companyId: manager.companyId?.toString() || null,
      isActive: manager.isActive,
    };
  }

  private getDefaultSubscriptionDates() {
    const startDate = new Date();
    const endDate = new Date(startDate);
    endDate.setFullYear(endDate.getFullYear() + 1);

    return {
      startDate,
      endDate,
      nextRenewalDate: new Date(endDate),
    };
  }

  private toDate(value?: string | Date) {
    return value ? new Date(value) : undefined;
  }

  async create(createCompanyDto: any, adminUser?: any) {
    const defaultSubscriptionDates = this.getDefaultSubscriptionDates();

    const company = await this.companyModel.create({
      shopName: createCompanyDto.shopName,
      ownerName: createCompanyDto.ownerName,
      ownerEmail: createCompanyDto.ownerEmail.trim().toLowerCase(),
      phone: createCompanyDto.phone || '',
      address: createCompanyDto.address || '',
      businessType: createCompanyDto.businessType || 'General',
      description: createCompanyDto.description || '',
      whatTheySell: createCompanyDto.whatTheySell || '',
      provinceOrCity: createCompanyDto.provinceOrCity || '',
      status: createCompanyDto.status || 'active',
      isActive: createCompanyDto.status !== 'inactive',
      subscriptionStatus: createCompanyDto.subscriptionStatus || 'Trial',
      subscriptionPrice: createCompanyDto.subscriptionPrice || 50,
      subscriptionStartDate:
        this.toDate(createCompanyDto.subscriptionStartDate) ||
        defaultSubscriptionDates.startDate,
      subscriptionEndDate:
        this.toDate(createCompanyDto.subscriptionEndDate) ||
        defaultSubscriptionDates.endDate,
      nextRenewalDate:
        this.toDate(createCompanyDto.nextRenewalDate) ||
        defaultSubscriptionDates.nextRenewalDate,
      createdByAdminId: adminUser?.userId
        ? new Types.ObjectId(adminUser.userId)
        : undefined,
    });

    return this.companyModel
      .findById(company._id)
      .populate('managerId', this.managerPopulateFields)
      .exec();
  }

  async findAll() {
    return this.companyModel
      .find()
      .populate('managerId', this.managerPopulateFields)
      .sort({ createdAt: -1 })
      .exec();
  }

  async findOne(id: string) {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('Invalid shop ID');
    }

    const company = await this.companyModel
      .findById(id)
      .populate('managerId', this.managerPopulateFields)
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
        typeof updateCompanyDto.isActive === 'boolean'
          ? updateCompanyDto.isActive
          : updateCompanyDto.subscriptionStatus === 'Suspended' ||
              updateCompanyDto.subscriptionStatus === 'Expired' ||
              updateCompanyDto.status === 'inactive'
            ? false
            : updateCompanyDto.subscriptionStatus === 'Trial' ||
                updateCompanyDto.subscriptionStatus === 'Active' ||
                updateCompanyDto.status === 'active'
              ? true
              : undefined,
      subscriptionStartDate: this.toDate(updateCompanyDto.subscriptionStartDate),
      subscriptionEndDate: this.toDate(updateCompanyDto.subscriptionEndDate),
      nextRenewalDate: this.toDate(updateCompanyDto.nextRenewalDate),
    };

    Object.keys(updateData).forEach((key) => {
      if (updateData[key] === undefined) {
        delete updateData[key];
      }
    });

    const company = await this.companyModel
      .findByIdAndUpdate(id, updateData, { new: true })
      .populate('managerId', this.managerPopulateFields)
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

  if (normalizeRole(manager.role) !== Role.MANAGER) {
    throw new BadRequestException('Only MANAGER accounts can be assigned to a shop');
  }

  const previousManagerId = company.managerId?.toString();
  if (previousManagerId && previousManagerId !== managerId) {
    const previousManager = await this.userModel.findById(previousManagerId);
    if (previousManager?.companyId?.toString() === companyId) {
      previousManager.companyId = undefined;
      await previousManager.save();
    }
  }

  await this.companyModel.updateMany(
    { managerId: manager._id, _id: { $ne: company._id } },
    { $unset: { managerId: 1 } },
  );

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
    .populate('managerId', this.managerPopulateFields)
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

    const existingAssignedManagerId = company.managerId?.toString();
    if (existingAssignedManagerId) {
      await this.userModel.findByIdAndUpdate(existingAssignedManagerId, {
        $unset: { companyId: 1 },
      });
    }

    const existingUser = await this.userModel
      .findOne({ email: managerDto.email.trim().toLowerCase() })
      .exec();

    const normalizedUsername = (managerDto.username || managerDto.email.split('@')[0])
      .trim()
      .toLowerCase();
    const temporaryPassword =
      managerDto.temporaryPassword ||
      managerDto.password ||
      `MGR-${randomBytes(4).toString('hex')}`;

    if (!normalizedUsername) {
      throw new BadRequestException('Username is required');
    }

    if (existingUser) {
      if (
        existingUser.username !== normalizedUsername &&
        (await this.userModel.findOne({ username: normalizedUsername }).exec())
      ) {
        throw new BadRequestException('Username already exists');
      }

      existingUser.role = Role.MANAGER;
      existingUser.companyId = company._id as Types.ObjectId;
      existingUser.name = managerDto.name || existingUser.name;
      existingUser.phone = managerDto.phone || existingUser.phone;
      existingUser.username = normalizedUsername;
      existingUser.isActive = true;
      existingUser.password = await bcrypt.hash(temporaryPassword, 10);
      await existingUser.save();

      await this.companyModel.updateMany(
        { managerId: existingUser._id, _id: { $ne: company._id } },
        { $unset: { managerId: 1 } },
      );

      company.managerId = existingUser._id as Types.ObjectId;
      await company.save();

      const shop = await this.companyModel
        .findById(companyId)
        .populate('managerId', this.managerPopulateFields)
        .exec();

      return {
        shop,
        manager: this.sanitizeManager(existingUser),
        credentials: {
          username: existingUser.username,
          temporaryPassword,
          email: existingUser.email,
        },
      };
    }

    const usernameExists = await this.userModel.findOne({
      username: normalizedUsername,
    });

    if (usernameExists) {
      throw new BadRequestException('Username already exists');
    }

    const hashedPassword = await bcrypt.hash(temporaryPassword, 10);

    const manager = await this.userModel.create({
      username: normalizedUsername,
      email: managerDto.email.trim().toLowerCase(),
      password: hashedPassword,
      name: managerDto.name,
      phone: managerDto.phone || '',
      role: Role.MANAGER,
      companyId: company._id,
      isActive: true,
    });

    company.managerId = manager._id as Types.ObjectId;
    await company.save();

    const shop = await this.companyModel
      .findById(companyId)
      .populate('managerId', this.managerPopulateFields)
      .exec();

    return {
      shop,
      manager: this.sanitizeManager(manager),
      credentials: {
        username: manager.username,
        temporaryPassword,
        email: manager.email,
      },
    };
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
