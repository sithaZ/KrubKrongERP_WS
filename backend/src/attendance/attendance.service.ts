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
import { ShopSettings } from './shop-settings.entity';

@Injectable()
export class AttendanceService {
  constructor(
    @InjectModel(Attendance.name)
    private attendanceModel: Model<Attendance>,
    @InjectModel(Employee.name)
    private employeeModel: Model<Employee>,
    @InjectModel(ShopSettings.name)
    private shopSettingsModel: Model<ShopSettings>,
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

  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371e3; // Earth radius in meters
    const φ1 = (lat1 * Math.PI) / 180;
    const φ2 = (lat2 * Math.PI) / 180;
    const Δφ = ((lat2 - lat1) * Math.PI) / 180;
    const Δλ = ((lon2 - lon1) * Math.PI) / 180;

    const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c; // Distance in meters
  }

  async checkIn(dto: CheckInDto) {
    // Find employee by ID or by associated userId
    let employee = await this.employeeModel.findById(dto.employeeId);
    if (!employee) {
      employee = await this.employeeModel.findOne({ userId: new Types.ObjectId(dto.employeeId) });
    }

    if (!employee || !employee.isActive) {
      throw new NotFoundException('Active employee record not found. Please ensure you are registered as an employee.');
    }

    const settings = await this.getShopSettings();
    let locationStatus: 'on_site' | 'remote' | 'unknown' = 'unknown';

    if (settings) {
      if (dto.qrToken && dto.qrToken !== settings.secretKey) {
        throw new BadRequestException('Invalid QR Code');
      }

      if (dto.lat && dto.lng) {
        const distance = this.calculateDistance(dto.lat, dto.lng, settings.coordinates.lat, settings.coordinates.lng);
        if (distance > settings.radius) {
          throw new BadRequestException(`Too far from shop (${Math.round(distance)}m). You must be within ${settings.radius}m.`);
        }
        locationStatus = 'on_site';
      }
    }

    const now = new Date();
    const workDate = this.getTodayString(now);

    const existing = await this.attendanceModel.findOne({
      employeeId: employee._id,
      workDate,
    });

    if (existing) {
      throw new BadRequestException('Already checked in today');
    }

    const attendance = new this.attendanceModel({
      employeeId: employee._id,
      workDate,
      checkIn: now,
      checkInLocation: dto.lat && dto.lng ? { lat: dto.lat, lng: dto.lng } : undefined,
      locationStatus,
      status: this.getStatusFromCheckIn(now),
      note: dto.note ?? '',
    });

    return attendance.save();
  }

  async checkOut(dto: CheckOutDto) {
    let employee = await this.employeeModel.findById(dto.employeeId);
    if (!employee) {
      employee = await this.employeeModel.findOne({ userId: new Types.ObjectId(dto.employeeId) });
    }

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    const settings = await this.getShopSettings();
    
    if (settings && dto.lat && dto.lng) {
      const distance = this.calculateDistance(dto.lat, dto.lng, settings.coordinates.lat, settings.coordinates.lng);
      if (distance > settings.radius) {
        throw new BadRequestException(`Too far from shop (${Math.round(distance)}m) to clock out.`);
      }
    }

    const now = new Date();
    const workDate = this.getTodayString(now);

    const attendance = await this.attendanceModel.findOne({
      employeeId: employee._id,
      workDate,
    });

    if (!attendance) {
      throw new NotFoundException('Attendance record not found for today');
    }

    if (attendance.checkOut) {
      throw new BadRequestException('Employee already checked out today');
    }

    if (!attendance.checkIn) {
      throw new BadRequestException('Cannot check out: missing check-in time record');
    }

    attendance.checkOut = now;
    attendance.checkOutLocation = dto.lat && dto.lng ? { lat: dto.lat, lng: dto.lng } : undefined;
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
        attendance.checkIn!,
        attendance.checkOut!,
      );
    }

    if (dto.note !== undefined) {
      attendance.note = dto.note;
    }

    return attendance.save();
  }

  async getShopSettings() {
    let settings = await this.shopSettingsModel.findOne();
    if (!settings) {
      // Create default settings if none exist
      settings = new this.shopSettingsModel({
        shopName: 'Default Shop',
        coordinates: { lat: 0, lng: 0 },
        radius: 50,
        secretKey: 'krobkrong_secret_123',
        ownerId: 'system',
      });
      await settings.save();
    }
    return settings;
  }

  async updateShopSettings(dto: any) {
    let settings = await this.shopSettingsModel.findOne();
    if (!settings) {
      settings = new this.shopSettingsModel(dto);
    } else {
      Object.assign(settings, dto);
    }
    return settings.save();
  }
}