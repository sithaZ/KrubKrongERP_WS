import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Payroll } from './payroll.entity';
import { Attendance } from '../attendance/attendance.entity';
import { Employee } from '../employees/employee.entity';
import { GeneratePayrollDto } from './dto/generate-payroll.dto';
import { Role } from '../common/enums/role.enum';
import { normalizeRole } from '../common/utils/role.utils';

type RequestUser = {
  userId: string;
  role?: string;
  companyId?: string | null;
};

@Injectable()
export class PayrollService {
  constructor(
    @InjectModel(Payroll.name) private payrollModel: Model<Payroll>,
    @InjectModel(Attendance.name) private attendanceModel: Model<Attendance>,
    @InjectModel(Employee.name) private employeeModel: Model<Employee>,
  ) {}

  private getNormalizedRole(user: RequestUser) {
    return normalizeRole(user.role);
  }

  private buildPayrollFilter(currentUser: RequestUser) {
    const normalizedRole = this.getNormalizedRole(currentUser);

    if (normalizedRole === Role.ADMIN) {
      return {};
    }

    if (normalizedRole === Role.MANAGER) {
      if (!currentUser.companyId) {
        if (currentUser.role?.toUpperCase() === 'ADMIN') return {};
        throw new ForbiddenException('Manager account is missing company access');
      }

      return {
        companyId: new Types.ObjectId(currentUser.companyId),
      };
    }

    return null;
  }

  private async resolveCurrentEmployee(currentUser: RequestUser) {
    const employee = await this.employeeModel.findOne({
      userId: new Types.ObjectId(currentUser.userId),
    });

    if (!employee) {
      throw new NotFoundException(
        'Employee profile not found for the current account',
      );
    }

    return employee;
  }

  private async findAccessibleEmployee(employeeId: string, currentUser: RequestUser) {
    const employee = await this.employeeModel.findById(employeeId);

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    const normalizedRole = this.getNormalizedRole(currentUser);

    if (normalizedRole === Role.ADMIN) {
      return employee;
    }

    if (normalizedRole === Role.MANAGER) {
      if (
        !currentUser.companyId ||
        employee.companyId?.toString() !== currentUser.companyId
      ) {
        throw new ForbiddenException('You cannot access another company\'s payroll data');
      }

      return employee;
    }

    if (employee.userId?.toString() !== currentUser.userId) {
      throw new ForbiddenException('You can only access your own payroll data');
    }

    return employee;
  }

  private async findAccessiblePayroll(id: string, currentUser: RequestUser) {
    const payroll = await this.payrollModel.findById(id);

    if (!payroll) {
      throw new NotFoundException('Payroll not found');
    }

    const employee = await this.employeeModel.findById(payroll.employeeId);
    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    await this.findAccessibleEmployee(employee._id.toString(), currentUser);
    return payroll;
  }

  private getMonthRange(month: string) {
    const [year, monthNumber] = month.split('-').map(Number);
    const start = `${year}-${String(monthNumber).padStart(2, '0')}-01`;
    const endDate = new Date(year, monthNumber, 0);
    const end = `${year}-${String(monthNumber).padStart(2, '0')}-${String(
      endDate.getDate(),
    ).padStart(2, '0')}`;

    return {
      start,
      end,
      totalDaysInMonth: endDate.getDate(),
    };
  }

  async generate(dto: GeneratePayrollDto, currentUser: RequestUser) {
    const employee = await this.findAccessibleEmployee(dto.employeeId, currentUser);

    const existing = await this.payrollModel.findOne({
      employeeId: new Types.ObjectId(dto.employeeId),
      month: dto.month,
    });

    if (existing && existing.status === 'finalized') {
      throw new BadRequestException('Payroll already finalized for this month');
    }

    const { start, end, totalDaysInMonth } = this.getMonthRange(dto.month);

    const records = await this.attendanceModel.find({
      employeeId: new Types.ObjectId(dto.employeeId),
      workDate: { $gte: start, $lte: end },
    });

    let presentDays = 0;
    let absentDays = 0;
    let lateDays = 0;
    let halfDays = 0;

    for (const record of records) {
      if (record.status === 'present') {
        presentDays++;
      }

      if (record.status === 'late') {
        lateDays++;
        presentDays++;
      }

      if (record.status === 'half_day') {
        halfDays++;
      }

      if (record.status === 'absent') {
        absentDays++;
      }
    }

    let grossSalary = 0;
    let deduction = 0;
    let netSalary = 0;

    if (employee.salaryType === 'daily') {
      grossSalary =
        presentDays * employee.baseSalary +
        halfDays * (employee.baseSalary / 2);

      deduction = 0;
      netSalary = grossSalary;
    } else if (employee.salaryType === 'monthly') {
      const dailyRate = employee.baseSalary / totalDaysInMonth;

      grossSalary = employee.baseSalary;
      deduction =
        absentDays * dailyRate + halfDays * (dailyRate / 2);

      netSalary = grossSalary - deduction;

      if (netSalary < 0) {
        netSalary = 0;
      }
    }

    const payload = {
      employeeId: new Types.ObjectId(dto.employeeId),
      companyId: employee.companyId,
      month: dto.month,
      presentDays,
      absentDays,
      lateDays,
      halfDays,
      grossSalary: Number(grossSalary.toFixed(2)),
      deduction: Number(deduction.toFixed(2)),
      netSalary: Number(netSalary.toFixed(2)),
      status: 'draft' as const,
    };

    const payroll = await this.payrollModel.findOneAndUpdate(
      {
        employeeId: new Types.ObjectId(dto.employeeId),
        month: dto.month,
      },
      payload,
      {
        upsert: true,
        new: true,
      },
    );

    return payroll;
  }

  async findAll(currentUser: RequestUser) {
    const accessFilter = this.buildPayrollFilter(currentUser);

    if (accessFilter) {
      return this.payrollModel
        .find(accessFilter)
        .sort({ month: -1, createdAt: -1 })
        .populate('employeeId');
    }

    const employee = await this.resolveCurrentEmployee(currentUser);

    return this.payrollModel
      .find({ employeeId: employee._id })
      .sort({ month: -1, createdAt: -1 })
      .populate('employeeId');
  }

  async findByEmployee(employeeId: string, currentUser: RequestUser) {
    const employee = await this.findAccessibleEmployee(employeeId, currentUser);

    return this.payrollModel
      .find({ employeeId: employee._id })
      .sort({ month: -1 })
      .populate('employeeId');
  }

  async findOneByEmployeeAndMonth(employeeId: string, month: string, currentUser: RequestUser) {
    const employee = await this.findAccessibleEmployee(employeeId, currentUser);

    const payroll = await this.payrollModel
      .findOne({
        employeeId: employee._id,
        month,
      })
      .populate('employeeId');

    if (!payroll) {
      throw new NotFoundException('Payroll not found');
    }

    return payroll;
  }

  async finalize(id: string, currentUser: RequestUser) {
    await this.findAccessiblePayroll(id, currentUser);

    const payroll = await this.payrollModel.findByIdAndUpdate(
      id,
      { status: 'finalized' },
      { new: true },
    );

    if (!payroll) {
      throw new NotFoundException('Payroll not found');
    }

    return payroll;
  }
}
