import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Payroll } from './payroll.entity';
import { Attendance } from '../attendance/attendance.entity';
import { Employee } from '../employees/employee.entity';
import { GeneratePayrollDto } from './dto/generate-payroll.dto';

@Injectable()
export class PayrollService {
  constructor(
    @InjectModel(Payroll.name) private payrollModel: Model<Payroll>,
    @InjectModel(Attendance.name) private attendanceModel: Model<Attendance>,
    @InjectModel(Employee.name) private employeeModel: Model<Employee>,
  ) {}

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

  async generate(dto: GeneratePayrollDto) {
    const employee = await this.employeeModel.findById(dto.employeeId);

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

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

  async findAll() {
    return this.payrollModel
      .find()
      .sort({ month: -1, createdAt: -1 })
      .populate('employeeId');
  }

  async findByEmployee(employeeId: string) {
    return this.payrollModel
      .find({ employeeId: new Types.ObjectId(employeeId) })
      .sort({ month: -1 })
      .populate('employeeId');
  }

  async findOneByEmployeeAndMonth(employeeId: string, month: string) {
    const payroll = await this.payrollModel
      .findOne({
        employeeId: new Types.ObjectId(employeeId),
        month,
      })
      .populate('employeeId');

    if (!payroll) {
      throw new NotFoundException('Payroll not found');
    }

    return payroll;
  }

  async finalize(id: string) {
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