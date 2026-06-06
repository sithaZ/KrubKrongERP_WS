import { IsBoolean, IsMongoId, IsOptional, IsString } from 'class-validator';

export class CheckInDto {
  @IsOptional()
  @IsMongoId()
  employeeId?: string;

  @IsOptional()
  @IsMongoId()
  staffId?: string;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  lat?: number;

  @IsOptional()
  lng?: number;

  @IsOptional()
  @IsString()
  qrToken?: string;

  @IsOptional()
  @IsBoolean()
  selfCheckIn?: boolean;
}