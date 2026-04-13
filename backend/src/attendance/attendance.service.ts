import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Attendance } from './attendance.entity';
import { CheckInDto } from './dto/check-in.dto';
import { CheckOutDto } from './dto/check-out.dto';
import { UpdateAttendanceDto } from './dto/update-attendance.dto';
import { Employee } from '../employees/employee.entity';

@Injectable()
export class AttendanceService {
  constructor(
    @InjectModel(Attendance.name)
    private attendanceModel: Model<Attendance>,
    @InjectModel(Employee.name)
    private employeeModel: Model<Employee>,
  ) {}

  private getTodayString(date = new Date()) {
    return date.toISOString().split('T')[0];
  }

  private getWorkedHours(checkIn: Date, checkOut: Date) {
    const diffMs = checkOut.getTime() - checkIn.getTime();

    if (diffMs < 0) {
      throw new BadRequestException('Check-out cannot be earlier than check-in');
    }

    const hours = diffMs / (1000 * 60 * 60);
    return Number(hours.toFixed(2));
  }

  private getStatusFromCheckIn(checkIn: Date) {
    const hour = checkIn.getHours();
    const minute = checkIn.getMinutes();

    if (hour > 8 || (hour === 8 && minute > 15)) {
      return 'late';
    }

    return 'present';
  }

  async checkIn(dto: CheckInDto) {
    const employee = await this.employeeModel.findById(dto.employeeId);

    if (!employee || !employee.isActive) {
      throw new NotFoundException('Active employee not found');
    }

    const now = new Date();
    const workDate = this.getTodayString(now);

    const existing = await this.attendanceModel.findOne({
      employeeId: new Types.ObjectId(dto.employeeId),
      workDate,
    });

    if (existing) {
      throw new BadRequestException('Employee already checked in today');
    }

    const attendance = new this.attendanceModel({
      employeeId: new Types.ObjectId(dto.employeeId),
      workDate,
      checkIn: now,
      status: this.getStatusFromCheckIn(now),
      note: dto.note ?? '',
    });

    return attendance.save();
  }

  async checkOut(dto: CheckOutDto) {
    const now = new Date();
    const workDate = this.getTodayString(now);

    const attendance = await this.attendanceModel.findOne({
      employeeId: new Types.ObjectId(dto.employeeId),
      workDate,
    });

    if (!attendance) {
      throw new NotFoundException('Attendance record not found for today');
    }

    if (attendance.checkOut) {
      throw new BadRequestException('Employee already checked out today');
    }

    if (!attendance.checkIn) {
      throw new BadRequestException('Cannot check out before check in');
    }

    attendance.checkOut = now;
    attendance.workedHours = this.getWorkedHours(attendance.checkIn, now);

    if (dto.note) {
      attendance.note = dto.note;
    }

    return attendance.save();
  }

  async findAll() {
    return this.attendanceModel
      .find()
      .sort({ workDate: -1, createdAt: -1 })
      .populate('employeeId');
  }

  async findByEmployee(employeeId: string) {
    return this.attendanceModel
      .find({ employeeId: new Types.ObjectId(employeeId) })
      .sort({ workDate: -1, createdAt: -1 })
      .populate('employeeId');
  }

  async update(id: string, dto: UpdateAttendanceDto) {
    const attendance = await this.attendanceModel.findById(id);

    if (!attendance) {
      throw new NotFoundException('Attendance not found');
    }

    if (dto.checkIn) {
      attendance.checkIn = new Date(dto.checkIn);
    }

    if (dto.checkOut) {
      attendance.checkOut = new Date(dto.checkOut);
    }

    if (dto.status) {
      attendance.status = dto.status;
    }

    if (typeof dto.workedHours === 'number') {
      attendance.workedHours = dto.workedHours;
    } else if (attendance.checkIn && attendance.checkOut) {
      attendance.workedHours = this.getWorkedHours(
        attendance.checkIn,
        attendance.checkOut,
      );
    }

    if (dto.note !== undefined) {
      attendance.note = dto.note;
    }

    return attendance.save();
  }
}