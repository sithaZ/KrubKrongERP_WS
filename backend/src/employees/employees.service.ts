import {
  BadRequestException,
  ConflictException,
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
import { Role } from '../common/enums/role.enum';

@Injectable()
export class EmployeesService {
  private static readonly EMPLOYEE_CODE_PREFIX = 'EMP';
  private static readonly EMPLOYEE_CODE_PAD_LENGTH = 3;
  private static readonly MAX_CREATE_RETRIES = 5;

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

  private formatEmployeeCode(sequence: number) {
    return `${EmployeesService.EMPLOYEE_CODE_PREFIX}${sequence
      .toString()
      .padStart(EmployeesService.EMPLOYEE_CODE_PAD_LENGTH, '0')}`;
  }

  private async getNextEmployeeCode() {
    const [latestEmployee] = await this.employeeModel.aggregate<{
      numericPart: number;
    }>([
      {
        $match: {
          employeeCode: {
            $regex: `^${EmployeesService.EMPLOYEE_CODE_PREFIX}[0-9]+$`,
          },
        },
      },
      {
        $addFields: {
          numericPart: {
            $toInt: {
              $substrCP: [
                '$employeeCode',
                EmployeesService.EMPLOYEE_CODE_PREFIX.length,
                {
                  $subtract: [
                    { $strLenCP: '$employeeCode' },
                    EmployeesService.EMPLOYEE_CODE_PREFIX.length,
                  ],
                },
              ],
            },
          },
        },
      },
      { $sort: { numericPart: -1 } },
      { $limit: 1 },
    ]);

    const nextSequence = (latestEmployee?.numericPart ?? 0) + 1;
    return this.formatEmployeeCode(nextSequence);
  }

  private isDuplicateKeyError(error: unknown) {
    return (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      error.code === 11000
    );
  }

  async create(createEmployeeDto: CreateEmployeeDto) {
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

    const temporaryPassword = this.generateTemporaryPassword();
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(temporaryPassword, salt);

    for (
      let attempt = 1;
      attempt <= EmployeesService.MAX_CREATE_RETRIES;
      attempt += 1
    ) {
      const employeeCode = await this.getNextEmployeeCode();
      const username = await this.generateUniqueUsername(employeeCode);
      let createdUser: Awaited<ReturnType<UsersService['create']>> | null = null;

      try {
        createdUser = await this.usersService.create({
          username,
          email: normalizedEmail,
          password: hashedPassword,
          role: Role.STAFF,
          isActive: createEmployeeDto.isActive ?? true,
        });

        const payload = {
          ...createEmployeeDto,
          employeeCode,
          email: normalizedEmail,
          userId: new Types.ObjectId(createdUser._id.toString()),
          hireDate: createEmployeeDto.hireDate
            ? new Date(createEmployeeDto.hireDate)
            : undefined,
        };

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
        if (createdUser) {
          await this.usersService.remove(createdUser._id.toString()).catch(() => {
            return undefined;
          });
        }

        if (
          this.isDuplicateKeyError(error) &&
          attempt < EmployeesService.MAX_CREATE_RETRIES
        ) {
          continue;
        }

        throw error;
      }
    }

    throw new ConflictException(
      'Unable to generate a unique employee code. Please try again.',
    );
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
