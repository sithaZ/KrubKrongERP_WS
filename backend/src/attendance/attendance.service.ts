import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Attendance, AttendanceStatus } from './attendance.entity';
import { CheckInDto } from './dto/check-in.dto';
import { CheckOutDto } from './dto/check-out.dto';
import { UpdateAttendanceDto } from './dto/update-attendance.dto';
import { CreateShiftDto } from './dto/create-shift.dto';
import { UpdateShiftDto } from './dto/update-shift.dto';
import { AssignShiftDto } from './dto/assign-shift.dto';
import { Employee } from '../employees/employee.entity';
import { ShopSettings } from './shop-settings.entity';
import { Shift } from './shift.entity';
import { Role } from '../common/enums/role.enum';
import { normalizeRole } from '../common/utils/role.utils';

type RequestUser = {
  userId: string;
  role?: string;
  companyId?: string | null;
};

const DEFAULT_SHIFT = {
  shiftName: 'Standard Day Shift',
  startTime: '08:00',
  endTime: '17:00',
  gracePeriodMinutes: 15,
  breakMinutes: 60,
  isActive: true,
};

@Injectable()
export class AttendanceService {
  constructor(
    @InjectModel(Attendance.name)
    private attendanceModel: Model<Attendance>,
    @InjectModel(Employee.name)
    private employeeModel: Model<Employee>,
    @InjectModel(ShopSettings.name)
    private shopSettingsModel: Model<ShopSettings>,
    @InjectModel(Shift.name)
    private shiftModel: Model<Shift>,
  ) {}

  private getNormalizedRole(user: RequestUser) {
    return normalizeRole(user.role);
  }

  private buildAttendanceFilter(currentUser: RequestUser) {
    const normalizedRole = this.getNormalizedRole(currentUser);

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
    const normalizedRole = this.getNormalizedRole(currentUser);
    let employee = await this.employeeModel.findById(employeeId);

    if (!employee) {
      employee = await this.employeeModel.findOne({
        userId: new Types.ObjectId(employeeId),
      });
    }

    if (!employee || !employee.isActive) {
      throw new NotFoundException(
        'Active employee record not found. Please ensure you are registered as an employee.',
      );
    }

    // Admins and owners bypass company restriction
    if (normalizedRole === Role.OWNER || currentUser.role?.toUpperCase() === 'ADMIN' || currentUser.role?.toUpperCase() === 'OWNER') {
      return employee;
    }

    if (normalizedRole === Role.MANAGER) {
      if (
        !currentUser.companyId ||
        employee.companyId?.toString() !== currentUser.companyId
      ) {
        throw new ForbiddenException('You cannot access another company\'s attendance data');
      }

      return employee;
    }

    if (employee.userId?.toString() !== currentUser.userId) {
      throw new ForbiddenException('You can only access your own attendance data');
    }

    return employee;
  }

  private getTodayString(date = new Date()) {
    return date.toISOString().split('T')[0];
  }

  private parseTime(timeStr: string, baseDate: Date): Date {
    const [hours, minutes] = timeStr.split(':').map(Number);
    const date = new Date(baseDate);
    date.setHours(hours, minutes, 0, 0);
    return date;
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

  // ───────────────────────────────────────────────────────────────────────────
  // SHIFT MANAGEMENT METHODS
  // ───────────────────────────────────────────────────────────────────────────
  async createShift(dto: CreateShiftDto) {
    const newShift = new this.shiftModel(dto);
    return newShift.save();
  }

  async findAllShifts() {
    return this.shiftModel.find().exec();
  }

  async findShiftById(id: string) {
    const shift = await this.shiftModel.findById(id).exec();
    if (!shift) {
      throw new NotFoundException(`Shift with ID ${id} not found`);
    }
    return shift;
  }

  async updateShift(id: string, dto: UpdateShiftDto) {
    const shift = await this.shiftModel.findByIdAndUpdate(id, dto, { new: true }).exec();
    if (!shift) {
      throw new NotFoundException(`Shift with ID ${id} not found`);
    }
    return shift;
  }

  async assignShift(dto: AssignShiftDto) {
    const employee = await this.employeeModel.findById(dto.employeeId);
    if (!employee) {
      throw new NotFoundException(`Employee with ID ${dto.employeeId} not found`);
    }

    const shift = await this.shiftModel.findById(dto.shiftId);
    if (!shift) {
      throw new NotFoundException(`Shift with ID ${dto.shiftId} not found`);
    }

    employee.shiftId = new Types.ObjectId(shift.id);
    return employee.save();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ATTENDANCE RECORDING METHODS
  // ───────────────────────────────────────────────────────────────────────────
  async checkIn(dto: CheckInDto, currentUser: RequestUser) {
    // Resolve employeeId using staffId if employeeId was not provided
    const targetId = dto.staffId || dto.employeeId;
    if (!targetId) {
      throw new BadRequestException('staffId or employeeId is required to check in');
    }

    const employee = await this.findAccessibleEmployee(targetId, currentUser);
    const settings = await this.getShopSettings();
    let locationStatus: 'on_site' | 'remote' | 'unknown' = 'unknown';

    if (settings) {
      if (dto.qrToken && dto.qrToken !== settings.secretKey) {
        throw new BadRequestException('The scanned QR code is invalid. Please make sure you scan the official shop QR code!');
      }

      if (dto.lat && dto.lng) {
        const distance = this.calculateDistance(dto.lat, dto.lng, settings.coordinates.lat, settings.coordinates.lng);
        if (distance > settings.radius) {
          throw new BadRequestException(`You are currently too far from the shop (${Math.round(distance)}m). Please move closer (within ${settings.radius}m) to check in!`);
        }
        locationStatus = 'on_site';
      }
    }

    const now = new Date();
    const attendanceDate = this.getTodayString(now);

    // Prevent future attendance records (if system clock is somehow skewed or client injects future dates)
    const todayStr = this.getTodayString();
    if (attendanceDate > todayStr) {
      throw new BadRequestException('Cannot record attendance in the future');
    }

    // Prevent double check-in per day
    const existing = await this.attendanceModel.findOne({
      staffId: employee._id,
      attendanceDate,
    });

    if (existing) {
      throw new BadRequestException('You have already checked in for today. Have a great workday!');
    }

    // Resolve shift info (Assigned shift or Default shift)
    let shift: any = DEFAULT_SHIFT;
    if (employee.shiftId) {
      const assignedShift = await this.shiftModel.findById(employee.shiftId);
      if (assignedShift && assignedShift.isActive) {
        shift = assignedShift;
      }
    }

    // Calculate lateness based on assigned shift
    const shiftStartTime = this.parseTime(shift.startTime, now);
    const graceLimit = new Date(shiftStartTime.getTime() + shift.gracePeriodMinutes * 60 * 1000);
    
    let lateMinutes = 0;
    let attendanceStatus = AttendanceStatus.PRESENT;

    if (now > graceLimit) {
      lateMinutes = Math.round((now.getTime() - shiftStartTime.getTime()) / (60 * 1000));
      attendanceStatus = AttendanceStatus.LATE;
    }

    const attendance = new this.attendanceModel({
      employeeId: employee._id,
      staffId: employee._id,
      companyId: employee.companyId,
      workDate: attendanceDate,
      attendanceDate,
      checkIn: now,
      checkInTime: now,
      checkInLocation: dto.lat && dto.lng ? { lat: dto.lat, lng: dto.lng } : undefined,
      locationStatus,
      status: lateMinutes > 0 ? 'late' : 'present',
      attendanceStatus,
      lateMinutes,
      note: dto.note ?? '',
      source: dto.qrToken ? 'qr' : 'mobile',
    });

    return attendance.save();
  }

  async checkOut(dto: CheckOutDto, currentUser: RequestUser) {
    const targetId = dto.staffId || dto.employeeId;
    if (!targetId) {
      throw new BadRequestException('staffId or employeeId is required to check out');
    }

    const employee = await this.findAccessibleEmployee(targetId, currentUser);
    const settings = await this.getShopSettings();
    
    if (settings && dto.lat && dto.lng) {
      const distance = this.calculateDistance(dto.lat, dto.lng, settings.coordinates.lat, settings.coordinates.lng);
      if (distance > settings.radius) {
        throw new BadRequestException(`You are currently too far from the shop (${Math.round(distance)}m) to check out. Please move closer (within ${settings.radius}m)!`);
      }
    }

    const now = new Date();
    const attendanceDate = this.getTodayString(now);

    const attendance = await this.attendanceModel.findOne({
      $or: [
        { staffId: employee._id, attendanceDate },
        { employeeId: employee._id, workDate: attendanceDate }
      ]
    });

    if (!attendance) {
      throw new NotFoundException("We couldn't find a check-in record for you today. Please check in first before checking out!");
    }

    // Self-healing legacy fields normalization
    if (!attendance.checkInTime && attendance.checkIn) {
      attendance.checkInTime = attendance.checkIn;
    }
    if (!attendance.staffId && attendance.employeeId) {
      attendance.staffId = attendance.employeeId;
    }
    if (!attendance.attendanceDate && attendance.workDate) {
      attendance.attendanceDate = attendance.workDate;
    }

    if (attendance.checkOutTime || attendance.checkOut) {
      throw new BadRequestException('You have already checked out for today. Have a restful evening!');
    }

    if (!attendance.checkInTime) {
      throw new BadRequestException('Cannot check out: missing check-in time record');
    }

    // Resolve shift info (Assigned shift or Default shift)
    let shift: any = DEFAULT_SHIFT;
    if (employee.shiftId) {
      const assignedShift = await this.shiftModel.findById(employee.shiftId);
      if (assignedShift && assignedShift.isActive) {
        shift = assignedShift;
      }
    }

    // Shift limits
    const shiftStartTime = this.parseTime(shift.startTime, attendance.checkInTime);
    const shiftEndTime = this.parseTime(shift.endTime, now);

    // Calculate worked hours (less break)
    const diffMs = now.getTime() - attendance.checkInTime.getTime();
    const totalHours = Math.max(0, diffMs / (1000 * 60 * 60));
    const breakHours = (shift.breakMinutes || 0) / 60;
    const netWorkedHours = Math.max(0, totalHours - breakHours);

    // Shift regular scheduled duration
    const shiftDurationMs = shiftEndTime.getTime() - shiftStartTime.getTime();
    const shiftDurationHours = Math.max(0, (shiftDurationMs / (1000 * 60 * 60)) - breakHours);

    // Work Hours (capped to standard shift duration) and Overtime Hours (extra hours)
    const workHours = Number(Math.min(netWorkedHours, shiftDurationHours).toFixed(2));
    const overtimeHours = Number(Math.max(0, netWorkedHours - shiftDurationHours).toFixed(2));

    // Calculate early leave minutes
    let earlyLeaveMinutes = 0;
    if (now < shiftEndTime) {
      earlyLeaveMinutes = Math.round((shiftEndTime.getTime() - now.getTime()) / (60 * 1000));
    }

    // Check if worked hours was too short to be considered half-day
    let finalStatus = attendance.status;
    let finalAttendanceStatus = attendance.attendanceStatus;

    if (netWorkedHours < shiftDurationHours / 2) {
      finalStatus = 'half_day';
      finalAttendanceStatus = AttendanceStatus.HALF_DAY;
    }

    attendance.checkOut = now;
    attendance.checkOutTime = now;
    attendance.checkOutLocation = dto.lat && dto.lng ? { lat: dto.lat, lng: dto.lng } : undefined;
    
    // Fill both old and new properties
    attendance.workedHours = workHours;
    attendance.workHours = workHours;
    attendance.overtimeHours = overtimeHours;
    attendance.earlyLeaveMinutes = earlyLeaveMinutes;
    attendance.status = finalStatus;
    attendance.attendanceStatus = finalAttendanceStatus;

    if (dto.note) {
      attendance.note = dto.note;
    }

    return attendance.save();
  }

  async getMyToday(currentUser: RequestUser) {
    const employee = await this.resolveCurrentEmployee(currentUser);
    const today = this.getTodayString();

    const record = await this.attendanceModel.findOne({
      staffId: employee._id,
      attendanceDate: today,
    });

    if (!record) {
      return { checkedIn: false, attendanceStatus: AttendanceStatus.ABSENT };
    }

    return record;
  }

  async getMe(currentUser: RequestUser) {
    const employee = await this.resolveCurrentEmployee(currentUser);
    return this.attendanceModel
      .find({ staffId: employee._id })
      .sort({ attendanceDate: -1, createdAt: -1 })
      .exec();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MANAGEMENT METHODS
  // ───────────────────────────────────────────────────────────────────────────
  async findAll(query: any, currentUser: RequestUser) {
    const normalizedRole = this.getNormalizedRole(currentUser);
    const filter: any = {};

    const isOwnerOrAdmin =
      currentUser.role?.toUpperCase() === 'OWNER' ||
      currentUser.role?.toUpperCase() === 'ADMIN';

    // RBAC check
    if (normalizedRole === Role.MANAGER && !isOwnerOrAdmin) {
      if (!currentUser.companyId) {
        throw new ForbiddenException('Manager account is missing company access');
      }
      filter.companyId = new Types.ObjectId(currentUser.companyId);
    } else if (!isOwnerOrAdmin) {
      throw new ForbiddenException('Only managers and owners can access global attendance records');
    }

    // Apply filters
    if (query.date) {
      filter.attendanceDate = query.date;
    }

    if (query.staff) {
      filter.staffId = new Types.ObjectId(query.staff);
    }

    if (query.status) {
      filter.attendanceStatus = query.status;
    }

    if (query.department) {
      const deptEmployees = await this.employeeModel.find({ department: query.department }, '_id');
      const ids = deptEmployees.map(e => e._id);
      filter.staffId = { $in: ids };
    }

    return this.attendanceModel
      .find(filter)
      .sort({ attendanceDate: -1, createdAt: -1 })
      .populate({
        path: 'staffId',
        populate: { path: 'shiftId' },
      })
      .populate({
        path: 'employeeId',
        populate: { path: 'shiftId' },
      })
      .exec();
  }

  async findOne(id: string, currentUser: RequestUser) {
    const attendance = await this.attendanceModel
      .findById(id)
      .populate({
        path: 'staffId',
        populate: { path: 'shiftId' },
      })
      .exec();
    if (!attendance) {
      throw new NotFoundException(`Attendance with ID ${id} not found`);
    }

    const employee = await this.employeeModel.findById(attendance.staffId);
    if (employee) {
      await this.findAccessibleEmployee(employee._id.toString(), currentUser);
    }

    return attendance;
  }

  async findByStaff(staffId: string, currentUser: RequestUser) {
    const employee = await this.findAccessibleEmployee(staffId, currentUser);
    return this.attendanceModel
      .find({ staffId: employee._id })
      .sort({ attendanceDate: -1, createdAt: -1 })
      .populate({
        path: 'staffId',
        populate: { path: 'shiftId' },
      })
      .exec();
  }

  async update(id: string, dto: UpdateAttendanceDto, currentUser: RequestUser) {
    const attendance = await this.attendanceModel.findById(id);
    if (!attendance) {
      throw new NotFoundException('Attendance not found');
    }

    const targetStaffId = attendance.staffId || attendance.employeeId;
    const employee = await this.employeeModel.findById(targetStaffId);
    if (!employee) {
      throw new NotFoundException('Employee associated with this attendance not found');
    }

    // RBAC: check if manager/owner has access to this employee
    await this.findAccessibleEmployee(employee._id.toString(), currentUser);

    // Self-healing legacy fields normalization
    if (!attendance.checkInTime && attendance.checkIn) {
      attendance.checkInTime = attendance.checkIn;
    }
    if (!attendance.checkOutTime && attendance.checkOut) {
      attendance.checkOutTime = attendance.checkOut;
    }
    if (!attendance.staffId && attendance.employeeId) {
      attendance.staffId = attendance.employeeId;
    }
    if (!attendance.attendanceDate && attendance.workDate) {
      attendance.attendanceDate = attendance.workDate;
    }

    const oldCheckIn = attendance.checkInTime;
    const oldCheckOut = attendance.checkOutTime;
    const oldStatus = attendance.attendanceStatus;

    const now = new Date();

    if (dto.attendanceDate) {
      // Prevent future dates
      const todayStr = this.getTodayString();
      if (dto.attendanceDate > todayStr) {
        throw new BadRequestException('Cannot record attendance in the future');
      }
      attendance.workDate = dto.attendanceDate;
      attendance.attendanceDate = dto.attendanceDate;
    }

    if (dto.checkIn || dto.checkInTime) {
      const checkInDate = new Date((dto.checkInTime || dto.checkIn)!);
      attendance.checkIn = checkInDate;
      attendance.checkInTime = checkInDate;
    }

    if (dto.checkOut || dto.checkOutTime) {
      const checkOutDate = new Date((dto.checkOutTime || dto.checkOut)!);
      attendance.checkOut = checkOutDate;
      attendance.checkOutTime = checkOutDate;
    }

    // Central calculations if check-in or check-out was corrected
    if (dto.checkInTime || dto.checkIn || dto.checkOutTime || dto.checkOut) {
      let shift: any = DEFAULT_SHIFT;
      if (employee.shiftId) {
        const assignedShift = await this.shiftModel.findById(employee.shiftId);
        if (assignedShift && assignedShift.isActive) {
          shift = assignedShift;
        }
      }

      if (attendance.checkInTime) {
        const shiftStartTime = this.parseTime(shift.startTime, attendance.checkInTime);
        const graceLimit = new Date(shiftStartTime.getTime() + shift.gracePeriodMinutes * 60 * 1000);
        
        if (attendance.checkInTime > graceLimit) {
          attendance.lateMinutes = Math.round((attendance.checkInTime.getTime() - shiftStartTime.getTime()) / (60 * 1000));
        } else {
          attendance.lateMinutes = 0;
        }
      }

      if (attendance.checkInTime && attendance.checkOutTime) {
        const shiftStartTime = this.parseTime(shift.startTime, attendance.checkInTime);
        const shiftEndTime = this.parseTime(shift.endTime, attendance.checkOutTime);

        const diffMs = attendance.checkOutTime.getTime() - attendance.checkInTime.getTime();
        const totalHours = Math.max(0, diffMs / (1000 * 60 * 60));
        const breakHours = (shift.breakMinutes || 0) / 60;
        const netWorkedHours = Math.max(0, totalHours - breakHours);

        const shiftDurationMs = shiftEndTime.getTime() - shiftStartTime.getTime();
        const shiftDurationHours = Math.max(0, (shiftDurationMs / (1000 * 60 * 60)) - breakHours);

        attendance.workHours = Number(Math.min(netWorkedHours, shiftDurationHours).toFixed(2));
        attendance.workedHours = attendance.workHours;
        attendance.overtimeHours = Number(Math.max(0, netWorkedHours - shiftDurationHours).toFixed(2));

        if (attendance.checkOutTime < shiftEndTime) {
          attendance.earlyLeaveMinutes = Math.round((shiftEndTime.getTime() - attendance.checkOutTime.getTime()) / (60 * 1000));
        } else {
          attendance.earlyLeaveMinutes = 0;
        }
      }
    }

    // Direct DTO overrides if specifically passed by manager
    if (dto.attendanceStatus) {
      attendance.attendanceStatus = dto.attendanceStatus;
      if (dto.attendanceStatus === AttendanceStatus.ABSENT) {
        attendance.status = 'absent';
      } else if (dto.attendanceStatus === AttendanceStatus.HALF_DAY) {
        attendance.status = 'half_day';
      } else if (dto.attendanceStatus === AttendanceStatus.LATE) {
        attendance.status = 'late';
      } else {
        attendance.status = 'present';
      }
    } else if (dto.status) {
      attendance.status = dto.status;
      if (dto.status === 'absent') {
        attendance.attendanceStatus = AttendanceStatus.ABSENT;
      } else if (dto.status === 'half_day') {
        attendance.attendanceStatus = AttendanceStatus.HALF_DAY;
      } else if (dto.status === 'late') {
        attendance.attendanceStatus = AttendanceStatus.LATE;
      } else {
        attendance.attendanceStatus = AttendanceStatus.PRESENT;
      }
    }

    if (typeof dto.workHours === 'number') {
      attendance.workHours = dto.workHours;
      attendance.workedHours = dto.workHours;
    } else if (typeof dto.workedHours === 'number') {
      attendance.workedHours = dto.workedHours;
      attendance.workHours = dto.workedHours;
    }

    if (typeof dto.overtimeHours === 'number') {
      attendance.overtimeHours = dto.overtimeHours;
    }

    if (typeof dto.lateMinutes === 'number') {
      attendance.lateMinutes = dto.lateMinutes;
    }

    if (typeof dto.earlyLeaveMinutes === 'number') {
      attendance.earlyLeaveMinutes = dto.earlyLeaveMinutes;
    }

    if (dto.note !== undefined) {
      attendance.note = dto.note;
    }

    const isChanged =
      (dto.checkInTime && dto.checkInTime !== oldCheckIn?.toISOString()) ||
      (dto.checkOutTime && dto.checkOutTime !== oldCheckOut?.toISOString()) ||
      (dto.attendanceStatus && dto.attendanceStatus !== oldStatus);

    if (isChanged) {
      if (!attendance.correctionHistory) {
        attendance.correctionHistory = [];
      }
      attendance.correctionHistory.push({
        correctedBy: new Types.ObjectId(currentUser.userId),
        correctedAt: new Date(),
        oldCheckIn,
        newCheckIn: attendance.checkInTime,
        oldCheckOut,
        newCheckOut: attendance.checkOutTime,
        oldStatus,
        newStatus: attendance.attendanceStatus,
        reason: dto.note || 'Manual manager correction',
      });
      attendance.source = 'manual';
    }

    return attendance.save();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STATISTICAL & REPORT ENDPOINTS
  // ───────────────────────────────────────────────────────────────────────────
  async getMonthlySummary(staffId: string, month: number, year: number, currentUser: RequestUser) {
    const employee = await this.findAccessibleEmployee(staffId, currentUser);

    const monthStr = month < 10 ? `0${month}` : `${month}`;
    const datePrefix = `${year}-${monthStr}`;

    const records = await this.attendanceModel.find({
      staffId: employee._id,
      attendanceDate: new RegExp(`^${datePrefix}`),
    }).exec();

    let totalPresentDays = 0;
    let totalAbsentDays = 0;
    let totalLateDays = 0;
    let totalLeaveDays = 0;
    let totalWorkHours = 0;
    let totalOvertimeHours = 0;

    for (const record of records) {
      if (record.attendanceStatus === AttendanceStatus.PRESENT) {
        totalPresentDays++;
      } else if (record.attendanceStatus === AttendanceStatus.LATE) {
        totalPresentDays++;
        totalLateDays++;
      } else if (record.attendanceStatus === AttendanceStatus.ABSENT) {
        totalAbsentDays++;
      } else if (record.attendanceStatus === AttendanceStatus.LEAVE) {
        totalLeaveDays++;
      } else if (record.attendanceStatus === AttendanceStatus.HALF_DAY) {
        totalPresentDays += 0.5;
      }

      totalWorkHours += record.workHours || 0;
      totalOvertimeHours += record.overtimeHours || 0;
    }

    return {
      totalPresentDays,
      totalAbsentDays,
      totalLateDays,
      totalLeaveDays,
      totalWorkHours: Number(totalWorkHours.toFixed(2)),
      totalOvertimeHours: Number(totalOvertimeHours.toFixed(2)),
    };
  }

  async getPayrollSummary(staffId: string, month: number, year: number, currentUser: RequestUser) {
    // Basic verification
    const employee = await this.findAccessibleEmployee(staffId, currentUser);

    const monthStr = month < 10 ? `0${month}` : `${month}`;
    const datePrefix = `${year}-${monthStr}`;

    const records = await this.attendanceModel.find({
      staffId: employee._id,
      attendanceDate: new RegExp(`^${datePrefix}`),
    }).exec();

    // Calculate calendar working days (weekdays: Mon-Fri) in that month
    let workingDays = 0;
    const daysInMonth = new Date(year, month, 0).getDate();
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month - 1, day);
      const dayOfWeek = date.getDay();
      if (dayOfWeek !== 0 && dayOfWeek !== 6) { // Not Sunday (0) and not Saturday (6)
        workingDays++;
      }
    }

    let attendedDays = 0;
    let absentDays = 0;
    let leaveDays = 0;
    let totalHours = 0;
    let overtimeHours = 0;
    let lateMinutes = 0;

    for (const r of records) {
      if (r.attendanceStatus === AttendanceStatus.PRESENT || r.attendanceStatus === AttendanceStatus.LATE) {
        attendedDays++;
      } else if (r.attendanceStatus === AttendanceStatus.HALF_DAY) {
        attendedDays += 0.5;
      } else if (r.attendanceStatus === AttendanceStatus.ABSENT) {
        absentDays++;
      } else if (r.attendanceStatus === AttendanceStatus.LEAVE) {
        leaveDays++;
      }

      totalHours += r.workHours || 0;
      overtimeHours += r.overtimeHours || 0;
      lateMinutes += r.lateMinutes || 0;
    }

    return {
      workingDays,
      attendedDays,
      absentDays,
      totalHours: Number(totalHours.toFixed(2)),
      overtimeHours: Number(overtimeHours.toFixed(2)),
      lateMinutes,
      leaveDays,
    };
  }

  async getDashboardMetrics(currentUser: RequestUser) {
    const normalizedRole = this.getNormalizedRole(currentUser);
    const filter: any = {};

    const isOwnerOrAdmin =
      currentUser.role?.toUpperCase() === 'OWNER' ||
      currentUser.role?.toUpperCase() === 'ADMIN';

    if (normalizedRole === Role.MANAGER && !isOwnerOrAdmin) {
      if (!currentUser.companyId) {
        throw new ForbiddenException('Manager account is missing company access');
      }
      filter.companyId = new Types.ObjectId(currentUser.companyId);
    } else if (!isOwnerOrAdmin) {
      throw new ForbiddenException('Only managers and owners can view dashboard analytics');
    }

    // Resolve total active employees in the filter company
    const totalEmployees = await this.employeeModel.countDocuments({
      ...filter,
      isActive: true,
    });

    const today = this.getTodayString();

    // Query today's attendance records for the filter
    const todayRecords = await this.attendanceModel.find({
      ...filter,
      attendanceDate: today,
    }).exec();

    let totalEmployeesPresentToday = 0;
    let totalEmployeesLateToday = 0;
    let totalEmployeesAbsentToday = 0;

    for (const r of todayRecords) {
      if (r.attendanceStatus === AttendanceStatus.PRESENT) {
        totalEmployeesPresentToday++;
      } else if (r.attendanceStatus === AttendanceStatus.LATE) {
        totalEmployeesPresentToday++;
        totalEmployeesLateToday++;
      } else if (r.attendanceStatus === AttendanceStatus.HALF_DAY) {
        totalEmployeesPresentToday++;
      } else if (r.attendanceStatus === AttendanceStatus.ABSENT) {
        totalEmployeesAbsentToday++;
      }
    }

    // Those who haven't checked in are considered absent in metrics
    const notCheckedIn = Math.max(0, totalEmployees - todayRecords.length);
    totalEmployeesAbsentToday += notCheckedIn;

    const attendanceRate = totalEmployees > 0 
      ? Number(((totalEmployeesPresentToday / totalEmployees) * 100).toFixed(1))
      : 100;

    return {
      totalEmployeesPresentToday,
      totalEmployeesAbsentToday,
      totalEmployeesLateToday,
      attendanceRate,
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SHOP SETTINGS
  // ───────────────────────────────────────────────────────────────────────────
  async getShopSettings() {
    let settings = await this.shopSettingsModel.findOne();
    if (!settings) {
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
