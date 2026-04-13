import { IsMongoId, IsOptional, IsString } from 'class-validator';

export class CheckOutDto {
  @IsMongoId()
  employeeId: string;

  @IsOptional()
  @IsString()
  note?: string;
}