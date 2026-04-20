import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';
import { Employee } from './employee.entity';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { UsersService } from '../users/users.service';

@Injectable()
export class EmployeesService {
  constructor(
    @InjectModel(Employee.name) private employeeModel: Model<Employee>,
    private usersService: UsersService,
  ) {}

  private normalizeEmail(email: string) {
    return email.trim().toLowerCase();
  }

  private normalizeUsername(seed: string) {
    return seed.trim().toLowerCase().replace(/[^a-z0-9]/g, '');
  }

  private async generateUniqueUsername(employeeCode: string) {
    const base = this.normalizeUsername(employeeCode);

    if (!base) {
      throw new BadRequestException('Employee code must contain letters or numbers');
    }

    let candidate = base;
    let suffix = 1;

    while (await this.usersService.findOneByUsername(candidate)) {
      suffix += 1;
      candidate = `${base}${suffix}`;
    }

    return candidate;
  }

  private generateTemporaryPassword() {
    return `ERP-${randomBytes(4).toString('hex')}`;
  }

  async create(createEmployeeDto: CreateEmployeeDto) {
    const existing = await this.employeeModel.findOne({
      employeeCode: createEmployeeDto.employeeCode,
    });

    if (existing) {
      throw new BadRequestException('Employee code already exists');
    }

    const normalizedEmail = this.normalizeEmail(createEmployeeDto.email);

    const existingEmployeeEmail = await this.employeeModel.findOne({
      email: normalizedEmail,
    });

    if (existingEmployeeEmail) {
      throw new BadRequestException('Employee email already exists');
    }

    const existingUserEmail = await this.usersService.findByEmail(normalizedEmail);

    if (existingUserEmail) {
      throw new BadRequestException('User email already exists');
    }

    const username = await this.generateUniqueUsername(createEmployeeDto.employeeCode);
    const temporaryPassword = this.generateTemporaryPassword();
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(temporaryPassword, salt);

    const user = await this.usersService.create({
      username,
      email: normalizedEmail,
      password: hashedPassword,
      role: 'employee',
      isActive: createEmployeeDto.isActive ?? true,
    });

    const payload = {
      ...createEmployeeDto,
      email: normalizedEmail,
      userId: new Types.ObjectId(user._id.toString()),
      hireDate: createEmployeeDto.hireDate
        ? new Date(createEmployeeDto.hireDate)
        : undefined,
    };

    try {
      const employee = new this.employeeModel(payload);
      const savedEmployee = await employee.save();

      return {
        employee: await savedEmployee.populate('userId'),
        credentials: {
          username,
          temporaryPassword,
          email: normalizedEmail,
        },
      };
    } catch (error) {
      await this.usersService.remove(user._id.toString());
      throw error;
    }
  }

  async findAll() {
    return this.employeeModel.find().sort({ createdAt: -1 }).populate('userId');
  }

  async findActive() {
    return this.employeeModel
      .find({ isActive: true })
      .sort({ createdAt: -1 })
      .populate('userId');
  }

  async findOne(id: string) {
    const employee = await this.employeeModel.findById(id).populate('userId');

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    return employee;
  }

  async update(id: string, updateEmployeeDto: UpdateEmployeeDto) {
    if (updateEmployeeDto.employeeCode) {
      const existing = await this.employeeModel.findOne({
        employeeCode: updateEmployeeDto.employeeCode,
        _id: { $ne: id },
      });

      if (existing) {
        throw new BadRequestException('Employee code already exists');
      }
    }

    if (updateEmployeeDto.email) {
      const normalizedEmail = this.normalizeEmail(updateEmployeeDto.email);
      const existingEmployeeEmail = await this.employeeModel.findOne({
        email: normalizedEmail,
        _id: { $ne: id },
      });

      if (existingEmployeeEmail) {
        throw new BadRequestException('Employee email already exists');
      }

      updateEmployeeDto.email = normalizedEmail;
    }

    const currentEmployee = await this.employeeModel.findById(id);

    if (!currentEmployee) {
      throw new NotFoundException('Employee not found');
    }

    const updatePayload: any = { ...updateEmployeeDto };

    if (updateEmployeeDto.userId) {
      updatePayload.userId = new Types.ObjectId(updateEmployeeDto.userId);
    }

    if (updateEmployeeDto.hireDate) {
      updatePayload.hireDate = new Date(updateEmployeeDto.hireDate);
    }

    if (currentEmployee.userId) {
      const userUpdatePayload: Record<string, unknown> = {};

      if (updateEmployeeDto.email) {
        const existingUserEmail = await this.usersService.findByEmail(updateEmployeeDto.email);

        if (existingUserEmail && existingUserEmail._id.toString() !== currentEmployee.userId.toString()) {
          throw new BadRequestException('User email already exists');
        }

        userUpdatePayload.email = updateEmployeeDto.email;
      }

      if (typeof updateEmployeeDto.isActive === 'boolean') {
        userUpdatePayload.isActive = updateEmployeeDto.isActive;
      }

      if (Object.keys(userUpdatePayload).length > 0) {
        await this.usersService.update(currentEmployee.userId.toString(), userUpdatePayload);
      }
    }

    const employee = await this.employeeModel
      .findByIdAndUpdate(id, updatePayload, { new: true })
      .populate('userId');

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    return employee;
  }

  async deactivate(id: string) {
    const currentEmployee = await this.employeeModel.findById(id);

    if (!currentEmployee) {
      throw new NotFoundException('Employee not found');
    }

    if (currentEmployee.userId) {
      await this.usersService.update(currentEmployee.userId.toString(), {
        isActive: false,
      });
    }

    const employee = await this.employeeModel
      .findByIdAndUpdate(id, { isActive: false }, { new: true })
      .populate('userId');

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    return employee;
  }
}
