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

  private async mapCompanyResponse(company: any) {
    const companyObj = company?.toObject ? company.toObject() : company;
    const ownerAccount = companyObj?.ownerId || companyObj?.managerId || null;
    const managers = await this.userModel
      .find({
        companyId: companyObj._id,
        role: { $in: [Role.MANAGER, Role.MANAGER.toLowerCase()] },
      })
      .sort({ createdAt: -1 })
      .exec();

    return {
      ...companyObj,
      ownerId: ownerAccount,
      // Preserve the legacy field for existing admin UI consumers.
      managerId: ownerAccount,
      managers: managers.map((manager) => this.sanitizeManager(manager)),
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

    const createdCompany = await this.companyModel
      .findById(company._id)
      .populate('ownerId', this.managerPopulateFields)
      .populate('managerId', this.managerPopulateFields)
      .exec();

    const shop = await this.mapCompanyResponse(createdCompany);

    if (!createCompanyDto.createOwnerAccount) {
      return shop;
    }

    const ownerResult = await this.createOwner(company._id.toString(), {
      name: createCompanyDto.ownerName,
      email: createCompanyDto.ownerEmail,
      phone: createCompanyDto.phone,
      username:
        createCompanyDto.ownerUsername || createCompanyDto.ownerEmail.split('@')[0],
      temporaryPassword: createCompanyDto.ownerTemporaryPassword,
    });

    return {
      shop: ownerResult.shop,
      owner: ownerResult.owner,
      credentials: ownerResult.credentials,
    };
  }

  async findAll() {
    const companies = await this.companyModel
      .find()
      .populate('ownerId', this.managerPopulateFields)
      .populate('managerId', this.managerPopulateFields)
      .sort({ createdAt: -1 })
      .exec();

    return Promise.all(
      companies.map((company) => this.mapCompanyResponse(company)),
    );
  }

  async findOne(id: string) {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('Invalid shop ID');
    }

    const company = await this.companyModel
      .findById(id)
      .populate('ownerId', this.managerPopulateFields)
      .populate('managerId', this.managerPopulateFields)
      .exec();

    if (!company) {
      throw new NotFoundException('Shop not found');
    }

    return this.mapCompanyResponse(company);
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
      .populate('ownerId', this.managerPopulateFields)
      .populate('managerId', this.managerPopulateFields)
      .exec();

    if (!company) {
      throw new NotFoundException('Shop not found');
    }

    return this.mapCompanyResponse(company);
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
      .findOne({ email: managerDto.email.trim().toLowerCase() })
      .exec();

    const normalizedUsername = (
      managerDto.username || managerDto.email.split('@')[0]
    ).trim();
    const temporaryPassword =
      managerDto.temporaryPassword ||
      managerDto.password ||
      `MGR-${randomBytes(4).toString('hex')}`;

    if (!normalizedUsername) {
      throw new BadRequestException('Username is required');
    }

    if (existingUser) {
      const existingRole = String(existingUser.role || '').trim().toUpperCase();

      if (existingRole && existingRole !== Role.MANAGER) {
        throw new BadRequestException(
          'This account already exists with a non-manager role.',
        );
      }

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

      return {
        shop: await this.mapCompanyResponse(
          await this.companyModel
            .findById(companyId)
            .populate('ownerId', this.managerPopulateFields)
            .populate('managerId', this.managerPopulateFields)
            .exec(),
        ),
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

    return {
      shop: await this.mapCompanyResponse(
        await this.companyModel
          .findById(companyId)
          .populate('ownerId', this.managerPopulateFields)
          .populate('managerId', this.managerPopulateFields)
          .exec(),
      ),
      manager: this.sanitizeManager(manager),
      credentials: {
        username: manager.username,
        temporaryPassword,
        email: manager.email,
      },
    };
  }

  async createOwner(companyId: string, ownerDto: any) {
    if (!Types.ObjectId.isValid(companyId)) {
      throw new BadRequestException('Invalid shop ID');
    }

    const company = await this.companyModel.findById(companyId).exec();

    if (!company) {
      throw new NotFoundException('Shop not found');
    }

    const existingUser = await this.userModel
      .findOne({ email: ownerDto.email.trim().toLowerCase() })
      .exec();

    const normalizedUsername = (
      ownerDto.username || ownerDto.email.split('@')[0]
    ).trim();
    const temporaryPassword =
      ownerDto.temporaryPassword ||
      ownerDto.password ||
      `OWN-${randomBytes(4).toString('hex')}`;

    if (!normalizedUsername) {
      throw new BadRequestException('Username is required');
    }

    const previousOwnerId =
      company.ownerId?.toString() || company.managerId?.toString() || null;

    let owner: User;

    if (existingUser) {
      if (
        existingUser.username !== normalizedUsername &&
        (await this.userModel.findOne({ username: normalizedUsername }).exec())
      ) {
        throw new BadRequestException('Username already exists');
      }

      owner = existingUser;
      owner.role = Role.OWNER;
      owner.companyId = company._id as Types.ObjectId;
      owner.name = ownerDto.name || owner.name;
      owner.phone = ownerDto.phone || owner.phone;
      owner.username = normalizedUsername;
      owner.isActive = true;
      owner.password = await bcrypt.hash(temporaryPassword, 10);
      await owner.save();
    } else {
      owner = await this.userModel.create({
        username: normalizedUsername,
        email: ownerDto.email.trim().toLowerCase(),
        password: await bcrypt.hash(temporaryPassword, 10),
        name: ownerDto.name,
        phone: ownerDto.phone || '',
        role: Role.OWNER,
        companyId: company._id,
        isActive: true,
      });
    }

    if (previousOwnerId && previousOwnerId !== owner._id.toString()) {
      await this.userModel.findByIdAndUpdate(previousOwnerId, {
        $unset: { companyId: 1 },
      });
    }

    await this.companyModel.updateMany(
      { ownerId: owner._id, _id: { $ne: company._id } },
      { $unset: { ownerId: 1, managerId: 1 } },
    );

    company.ownerId = owner._id as Types.ObjectId;
    company.managerId = owner._id as Types.ObjectId;
    await company.save();

    return {
      shop: await this.mapCompanyResponse(
        await this.companyModel
          .findById(companyId)
          .populate('ownerId', this.managerPopulateFields)
          .populate('managerId', this.managerPopulateFields)
          .exec(),
      ),
      owner: this.sanitizeManager(owner),
      credentials: {
        username: owner.username,
        temporaryPassword,
        email: owner.email,
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
