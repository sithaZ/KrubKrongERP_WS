import { IsBoolean, IsNumber, IsOptional, IsString, Matches, Min } from 'class-validator';

export class CreateShiftDto {
  @IsString()
  shiftName: string;

  @IsString()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'startTime must be in HH:MM format (e.g. 08:00)' })
  startTime: string;

  @IsString()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'endTime must be in HH:MM format (e.g. 17:00)' })
  endTime: string;

  @IsNumber()
  @Min(0)
  gracePeriodMinutes: number;

  @IsNumber()
  @Min(0)
  breakMinutes: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
