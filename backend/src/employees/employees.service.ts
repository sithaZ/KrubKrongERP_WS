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
import { Employee } from './employee.entity';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { UsersService } from '../users/users.service';
import { Role } from '../common/enums/role.enum';
import { normalizeRole } from '../common/utils/role.utils';

type RequestUser = {
  userId: string;
  role?: string;
  companyId?: string | null;
};

@Injectable()
export class EmployeesService {
  private static readonly EMPLOYEE_CODE_PREFIX = 'EMP';
  private static readonly EMPLOYEE_CODE_PAD_LENGTH = 3;
  private static readonly MAX_CREATE_RETRIES = 5;

  constructor(
    @InjectModel(Employee.name) private employeeModel: Model<Employee>,
    private usersService: UsersService,
  ) {}

  private getNormalizedRole(user: RequestUser) {
    return normalizeRole(user.role);
  }

  private toObjectId(value?: string | null) {
    return value ? new Types.ObjectId(value) : undefined;
  }

  private resolveCompanyId(companyId: string | undefined, currentUser: RequestUser) {
    const normalizedRole = this.getNormalizedRole(currentUser);

    if (normalizedRole === Role.MANAGER) {
      // Allow creation even if companyId is missing for the manager, 
      // but use it if it exists.
      return currentUser.companyId ? new Types.ObjectId(currentUser.companyId) : undefined;
    }

    if (normalizedRole === Role.ADMIN && !companyId) {
      throw new BadRequestException('shopId/companyId is required for ADMIN employee creation');
    }

    return this.toObjectId(companyId);
  }

  private buildAccessFilter(currentUser: RequestUser) {
    const normalizedRole = this.getNormalizedRole(currentUser);

    if (normalizedRole === Role.ADMIN) {
      return {};
    }

    if (normalizedRole === Role.MANAGER) {
      if (currentUser.companyId) {
        return {
          companyId: new Types.ObjectId(currentUser.companyId),
        };
      }
      
      // If no companyId, manager can only see employees they created 
      // or those explicitly assigned to them via userId
      return {}; 
    }

    return {
      userId: new Types.ObjectId(currentUser.userId),
    };
  }

  private assertEmployeeAccess(employee: Employee, currentUser: RequestUser) {
    const normalizedRole = this.getNormalizedRole(currentUser);

    if (normalizedRole === Role.ADMIN) {
      return;
    }

    if (normalizedRole === Role.MANAGER) {
      // If manager has a company, enforce matching companyId
      if (currentUser.companyId) {
        if (employee.companyId?.toString() !== currentUser.companyId) {
          throw new ForbiddenException('You cannot access another company\'s employee data');
        }
        return;
      }
      
      // If manager has no company, they can only access employees with no company
      if (employee.companyId) {
        throw new ForbiddenException('You do not have access to this company\'s data');
      }

      return;
    }

    if (employee.userId?.toString() !== currentUser.userId) {
      throw new ForbiddenException('You can only access your own employee record');
    }
  }

  private normalizeEmail(email: string) {
    return email.trim().toLowerCase();
  }

  private normalizeUsername(seed: string) {
    return seed
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]/g, '');
  }

  private async generateUniqueUsername(employeeCode: string) {
    const base = this.normalizeUsername(employeeCode);

    if (!base) {
      throw new BadRequestException(
        'Employee code must contain letters or numbers',
      );
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

  async create(createEmployeeDto: CreateEmployeeDto, currentUser: RequestUser) {
    const normalizedEmail = this.normalizeEmail(createEmployeeDto.email);
    const companyId = this.resolveCompanyId(
      createEmployeeDto.companyId,
      currentUser,
    );

    const existingEmployeeEmail = await this.employeeModel.findOne({
      email: normalizedEmail,
    });

    if (existingEmployeeEmail) {
      throw new BadRequestException('Employee email already exists');
    }

    const existingUserEmail =
      await this.usersService.findByEmail(normalizedEmail);

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
      let createdUser: Awaited<ReturnType<UsersService['create']>> | null =
        null;

      try {
        const staffName = createEmployeeDto.fullName;

        createdUser = await this.usersService.create({
          username,
          name: staffName,
          email: normalizedEmail,
          password: hashedPassword,
          role: Role.EMPLOYEE,
          companyId,
          isActive: createEmployeeDto.isActive ?? true,
          phone: createEmployeeDto.phone,
        });

        const payload = {
          ...createEmployeeDto,
          employeeCode,
          email: normalizedEmail,
          companyId,
          userId: createdUser._id,
          hireDate: createEmployeeDto.hireDate
            ? new Date(createEmployeeDto.hireDate)
            : undefined,
        };

        const employee = new this.employeeModel(payload);
        const savedEmployee = await employee.save();
        const populatedEmployee = await savedEmployee.populate('userId');

        return {
          employee: populatedEmployee.toObject(),
          credentials: {
            username,
            temporaryPassword,
            email: normalizedEmail,
          },
        };
      } catch (error) {
        console.error('CRITICAL ERROR in EmployeesService.create:', error);

        if (createdUser) {
          await this.usersService
            .remove(createdUser._id.toString())
            .catch((e) => {
              console.error(
                'Failed to cleanup user after employee creation failure:',
                e,
              );
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

  async findAll(currentUser: RequestUser) {
    return this.employeeModel
      .find(this.buildAccessFilter(currentUser))
      .sort({ createdAt: -1 })
      .populate('userId');
  }

  async findActive(currentUser: RequestUser) {
    return this.employeeModel
      .find({ ...this.buildAccessFilter(currentUser), isActive: true })
      .sort({ createdAt: -1 })
      .populate('userId');
  }

  async findOne(id: string, currentUser: RequestUser) {
    const employee = await this.employeeModel.findById(id).populate('userId');

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    this.assertEmployeeAccess(employee, currentUser);

    return employee;
  }

  async update(id: string, updateEmployeeDto: UpdateEmployeeDto, currentUser: RequestUser) {
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

    this.assertEmployeeAccess(currentEmployee, currentUser);

    const updatePayload: any = { ...updateEmployeeDto };
    const companyId = this.resolveCompanyId(updateEmployeeDto.companyId, currentUser);

    if (updateEmployeeDto.userId) {
      updatePayload.userId = new Types.ObjectId(updateEmployeeDto.userId);
    }

    if (companyId) {
      updatePayload.companyId = companyId;
    }

    if (updateEmployeeDto.hireDate) {
      updatePayload.hireDate = new Date(updateEmployeeDto.hireDate);
    }

    if (currentEmployee.userId) {
      const userUpdatePayload: Record<string, unknown> = {};

      if (updateEmployeeDto.email) {
        const existingUserEmail = await this.usersService.findByEmail(
          updateEmployeeDto.email,
        );

        if (
          existingUserEmail &&
          existingUserEmail._id.toString() !== currentEmployee.userId.toString()
        ) {
          throw new BadRequestException('User email already exists');
        }

        userUpdatePayload.email = updateEmployeeDto.email;
      }

      if (typeof updateEmployeeDto.isActive === 'boolean') {
        userUpdatePayload.isActive = updateEmployeeDto.isActive;
      }

      if (companyId) {
        userUpdatePayload.companyId = companyId;
      }

      if (Object.keys(userUpdatePayload).length > 0) {
        await this.usersService.update(
          currentEmployee.userId.toString(),
          userUpdatePayload,
        );
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

  async deactivate(id: string, currentUser: RequestUser) {
    const currentEmployee = await this.employeeModel.findById(id);

    if (!currentEmployee) {
      throw new NotFoundException('Employee not found');
    }

    this.assertEmployeeAccess(currentEmployee, currentUser);

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
