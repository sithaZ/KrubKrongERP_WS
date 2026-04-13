import { IsMongoId, IsOptional, IsString } from 'class-validator';

export class CheckInDto {
  @IsMongoId()
  employeeId: string;

  @IsOptional()
  @IsString()
  note?: string;
}