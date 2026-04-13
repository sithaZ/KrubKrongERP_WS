import { IsMongoId, IsString, Matches } from 'class-validator';

export class GeneratePayrollDto {
  @IsMongoId()
  employeeId: string;

  @IsString()
  @Matches(/^\d{4}-\d{2}$/)
  month: string;
}