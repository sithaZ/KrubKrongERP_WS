import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Employee } from './employee.entity';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';

@Injectable()
export class EmployeesService {
  constructor(
    @InjectModel(Employee.name) private employeeModel: Model<Employee>,
  ) {}

  async create(createEmployeeDto: CreateEmployeeDto) {
    const existing = await this.employeeModel.findOne({
      employeeCode: createEmployeeDto.employeeCode,
    });

    if (existing) {
      throw new BadRequestException('Employee code already exists');
    }

    const payload = {
      ...createEmployeeDto,
      userId: createEmployeeDto.userId
        ? new Types.ObjectId(createEmployeeDto.userId)
        : undefined,
      hireDate: createEmployeeDto.hireDate
        ? new Date(createEmployeeDto.hireDate)
        : undefined,
    };

    const employee = new this.employeeModel(payload);
    return employee.save();
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

    const updatePayload: any = { ...updateEmployeeDto };

    if (updateEmployeeDto.userId) {
      updatePayload.userId = new Types.ObjectId(updateEmployeeDto.userId);
    }

    if (updateEmployeeDto.hireDate) {
      updatePayload.hireDate = new Date(updateEmployeeDto.hireDate);
    }

    const employee = await this.employeeModel.findByIdAndUpdate(
      id,
      updatePayload,
      { new: true },
    );

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    return employee;
  }

  async deactivate(id: string) {
    const employee = await this.employeeModel.findByIdAndUpdate(
      id,
      { isActive: false },
      { new: true },
    );

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    return employee;
  }
}