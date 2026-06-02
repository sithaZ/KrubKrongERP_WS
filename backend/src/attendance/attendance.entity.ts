import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export enum AttendanceStatus {
  PRESENT = 'PRESENT',
  ABSENT = 'ABSENT',
  LATE = 'LATE',
  HALF_DAY = 'HALF_DAY',
  LEAVE = 'LEAVE',
  HOLIDAY = 'HOLIDAY',
}

@Schema({ timestamps: true })
export class Attendance extends Document {
  // Existing field for mobile compatibility
  @Prop({ type: Types.ObjectId, ref: 'Employee', required: true })
  employeeId: Types.ObjectId;

  // New field as requested
  @Prop({ type: Types.ObjectId, ref: 'Employee', required: false, index: true })
  staffId?: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Company', required: false, index: true })
  companyId?: Types.ObjectId;

  // Existing field
  @Prop({ required: true })
  workDate: string;

  // New field
  @Prop({ required: false, index: true })
  attendanceDate?: string;

  // Existing fields
  @Prop()
  checkIn?: Date;

  @Prop()
  checkOut?: Date;

  // New fields
  @Prop()
  checkInTime?: Date;

  @Prop()
  checkOutTime?: Date;

  @Prop({ type: Object })
  checkInLocation?: { lat: number; lng: number };

  @Prop({ type: Object })
  checkOutLocation?: { lat: number; lng: number };

  @Prop({
    required: true,
    enum: ['on_site', 'remote', 'unknown'],
    default: 'unknown',
  })
  locationStatus: 'on_site' | 'remote' | 'unknown';

  // Existing field
  @Prop({
    required: true,
    enum: ['present', 'absent', 'late', 'half_day'],
    default: 'present',
  })
  status: 'present' | 'absent' | 'late' | 'half_day';

  // New field enum
  @Prop({
    required: true,
    enum: Object.values(AttendanceStatus),
    default: AttendanceStatus.PRESENT,
  })
  attendanceStatus: AttendanceStatus;

  // Existing field
  @Prop({ default: 0 })
  workedHours: number;

  // New field
  @Prop({ default: 0 })
  workHours: number;

  @Prop({ default: 0 })
  overtimeHours: number;

  @Prop({ default: 0 })
  lateMinutes: number;

  @Prop({ default: 0 })
  earlyLeaveMinutes: number;

  @Prop({ default: '' })
  note: string;

  @Prop({
    required: true,
    enum: ['mobile', 'qr', 'manual'],
    default: 'qr',
  })
  source: 'mobile' | 'qr' | 'manual';

  @Prop({ type: [Object], default: [] })
  correctionHistory: Array<{
    correctedBy: Types.ObjectId;
    correctedAt: Date;
    oldCheckIn?: Date;
    newCheckIn?: Date;
    oldCheckOut?: Date;
    newCheckOut?: Date;
    oldStatus?: string;
    newStatus?: string;
    reason: string;
  }>;
}

export const AttendanceSchema = SchemaFactory.createForClass(Attendance);

// Unique compound index as requested
AttendanceSchema.index({ staffId: 1, attendanceDate: 1 }, { unique: true });

// Existing unique compound index for backward compatibility
AttendanceSchema.index({ employeeId: 1, workDate: 1 }, { unique: true });
