import {
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { AttendanceStatus } from '../attendance.entity';

export class UpdateAttendanceDto {
  @IsOptional()
  @IsDateString()
  checkIn?: string;

  @IsOptional()
  @IsDateString()
  checkOut?: string;

  @IsOptional()
  @IsDateString()
  checkInTime?: string;

  @IsOptional()
  @IsDateString()
  checkOutTime?: string;

  @IsOptional()
  @IsEnum(['present', 'absent', 'late', 'half_day'])
  status?: 'present' | 'absent' | 'late' | 'half_day';

  @IsOptional()
  @IsEnum(AttendanceStatus)
  attendanceStatus?: AttendanceStatus;

  @IsOptional()
  @IsNumber()
  @Min(0)
  workedHours?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  workHours?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  overtimeHours?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  lateMinutes?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  earlyLeaveMinutes?: number;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsString()
  attendanceDate?: string;
}