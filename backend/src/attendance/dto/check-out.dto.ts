import { IsMongoId, IsOptional, IsString } from 'class-validator';

export class CheckOutDto {
  @IsMongoId()
  employeeId: string;

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