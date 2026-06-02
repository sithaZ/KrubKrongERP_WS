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
  shopId?: string | null;
};

@Injectable()
export class EmployeesService {
  private static readonly EMPLOYEE_CODE_PREFIX = 'EMP';
  private static readonly EMPLOYEE_CODE_PAD_LENGTH = 3;
  private static readonly MAX_CREATE_RETRIES = 5;
  private readonly safeUserPopulate =
    'name email username phone role isActive companyId createdAt updatedAt';

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

  private getScopedShopId(currentUser: RequestUser) {
    return currentUser.shopId || currentUser.companyId || null;
  }

  private getManagerShopObjectId(currentUser: RequestUser) {
    const shopId = this.getScopedShopId(currentUser);

    if (!shopId) {
      throw new ForbiddenException(
        'Manager must be assigned to a shop before managing employees',
      );
    }

    return new Types.ObjectId(shopId);
  }

  private buildAccessFilter(currentUser: RequestUser) {
    const normalizedRole = this.getNormalizedRole(currentUser);

    if (normalizedRole === Role.MANAGER) {
      const shopId = this.getScopedShopId(currentUser);

      if (shopId) {
        return {
          companyId: new Types.ObjectId(shopId),
        };
      }

      return {
        _id: { $exists: false },
      };
    }

    return {
      userId: new Types.ObjectId(currentUser.userId),
    };
  }

  private assertEmployeeAccess(employee: Employee, currentUser: RequestUser) {
    const normalizedRole = this.getNormalizedRole(currentUser);

    if (normalizedRole === Role.MANAGER) {
      const shopId = this.getScopedShopId(currentUser);

      if (!shopId) {
        throw new ForbiddenException(
          'Manager must be assigned to a shop before accessing employees',
        );
      }

      if (employee.companyId?.toString() !== shopId) {
        throw new ForbiddenException(
          'You cannot access another shop employee record',
        );
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
    const normalizedRole = this.getNormalizedRole(currentUser);

    if (normalizedRole !== Role.MANAGER) {
      throw new ForbiddenException('Only managers can create employees');
    }

    const requestedShopId = createEmployeeDto.shopId || createEmployeeDto.companyId;
    const currentShopId = this.getScopedShopId(currentUser);

    if (requestedShopId && currentShopId && requestedShopId !== currentShopId) {
      throw new ForbiddenException(
        'Managers can only create employees inside their own shop',
      );
    }

    const normalizedEmail = this.normalizeEmail(createEmployeeDto.email);
    const companyId = this.getManagerShopObjectId(currentUser);

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
        const positionName = createEmployeeDto.position?.trim().toLowerCase();
        const userRole = positionName === 'manager' ? Role.MANAGER : Role.EMPLOYEE;

        createdUser = await this.usersService.createEmployeeAccount({
          username,
          name: staffName,
          email: normalizedEmail,
          password: hashedPassword,
          role: userRole,
          companyId,
          isActive: createEmployeeDto.isActive ?? true,
          phone: createEmployeeDto.phone,
        });

        const payload = {
          ...createEmployeeDto,
          employeeCode,
          email: normalizedEmail,
          companyId,
          shopId: companyId.toString(),
          userId: createdUser._id,
          hireDate: createEmployeeDto.hireDate
            ? new Date(createEmployeeDto.hireDate)
            : undefined,
        };

        const employee = new this.employeeModel(payload);
        const savedEmployee = await employee.save();
        const populatedEmployee = await savedEmployee.populate(
          'userId',
          this.safeUserPopulate,
        );

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
            .removeEmployeeAccount(createdUser._id.toString())
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
      .populate('userId', this.safeUserPopulate);
  }

  async findActive(currentUser: RequestUser) {
    return this.employeeModel
      .find({ ...this.buildAccessFilter(currentUser), isActive: true })
      .sort({ createdAt: -1 })
      .populate('userId', this.safeUserPopulate);
  }

  async findOne(id: string, currentUser: RequestUser) {
    const employee = await this.employeeModel
      .findById(id)
      .populate('userId', this.safeUserPopulate);

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    this.assertEmployeeAccess(employee, currentUser);

    return employee;
  }

  async update(id: string, updateEmployeeDto: UpdateEmployeeDto, currentUser: RequestUser) {
    const normalizedRole = this.getNormalizedRole(currentUser);

    if (normalizedRole === Role.ADMIN) {
      throw new ForbiddenException('ADMIN cannot manage employee records');
    }

    if (normalizedRole !== Role.MANAGER) {
      throw new ForbiddenException('Only managers can update employee records');
    }

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

    const requestedShopId = updateEmployeeDto.shopId || updateEmployeeDto.companyId;
    const currentShopId = this.getScopedShopId(currentUser);

    if (requestedShopId && currentShopId && requestedShopId !== currentShopId) {
      throw new ForbiddenException(
        'Managers cannot move employees to another shop',
      );
    }

    const updatePayload: any = { ...updateEmployeeDto };
    delete updatePayload.userId;
    delete updatePayload.shopId;
    updatePayload.companyId = this.getManagerShopObjectId(currentUser);

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

      if (updateEmployeeDto.position) {
        const positionName = updateEmployeeDto.position.trim().toLowerCase();
        userUpdatePayload.role = positionName === 'manager' ? Role.MANAGER : Role.EMPLOYEE;
      }

      userUpdatePayload.companyId = updatePayload.companyId;

      if (Object.keys(userUpdatePayload).length > 0) {
        await this.usersService.updateEmployeeAccount(
          currentEmployee.userId.toString(),
          userUpdatePayload,
        );
      }
    }

    const employee = await this.employeeModel
      .findByIdAndUpdate(id, updatePayload, { new: true })
      .populate('userId', this.safeUserPopulate);

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    return employee;
  }

  async deactivate(id: string, currentUser: RequestUser) {
    const normalizedRole = this.getNormalizedRole(currentUser);

    if (normalizedRole === Role.ADMIN) {
      throw new ForbiddenException('ADMIN cannot manage employee records');
    }

    if (normalizedRole !== Role.MANAGER) {
      throw new ForbiddenException('Only managers can deactivate employees');
    }

    const currentEmployee = await this.employeeModel.findById(id);

    if (!currentEmployee) {
      throw new NotFoundException('Employee not found');
    }

    this.assertEmployeeAccess(currentEmployee, currentUser);

    if (currentEmployee.userId) {
      await this.usersService.updateEmployeeAccount(currentEmployee.userId.toString(), {
        isActive: false,
      });
    }

    const employee = await this.employeeModel
      .findByIdAndUpdate(id, { isActive: false }, { new: true })
      .populate('userId', this.safeUserPopulate);

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    return employee;
  }
}
