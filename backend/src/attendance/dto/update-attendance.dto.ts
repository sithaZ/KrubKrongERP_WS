import {
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class UpdateAttendanceDto {
  @IsOptional()
  @IsDateString()
  checkIn?: string;

  @IsOptional()
  @IsDateString()
  checkOut?: string;

  @IsOptional()
  @IsEnum(['present', 'absent', 'late', 'half_day'])
  status?: 'present' | 'absent' | 'late' | 'half_day';

  @IsOptional()
  @IsNumber()
  @Min(0)
  workedHours?: number;

  @IsOptional()
  @IsString()
  note?: string;
}