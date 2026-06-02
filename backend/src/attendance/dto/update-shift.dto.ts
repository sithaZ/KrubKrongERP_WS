import { IsBoolean, IsNumber, IsOptional, IsString, Matches, Min } from 'class-validator';

export class UpdateShiftDto {
  @IsOptional()
  @IsString()
  shiftName?: string;

  @IsOptional()
  @IsString()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'startTime must be in HH:MM format (e.g. 08:00)' })
  startTime?: string;

  @IsOptional()
  @IsString()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'endTime must be in HH:MM format (e.g. 17:00)' })
  endTime?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  gracePeriodMinutes?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  breakMinutes?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
