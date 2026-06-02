import { IsMongoId, IsOptional, IsString } from 'class-validator';

export class CheckOutDto {
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
}