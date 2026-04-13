import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsMongoId,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class CreateEmployeeDto {
  @IsOptional()
  @IsMongoId()
  userId?: string;

  @IsString()
  fullName: string;

  @IsString()
  employeeCode: string;

  @IsOptional()
  @IsString()
  position?: string;

  @IsOptional()
  @IsString()
  department?: string;

  @IsEnum(['daily', 'monthly'])
  salaryType: 'daily' | 'monthly';

  @IsNumber()
  @Min(0)
  baseSalary: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsDateString()
  hireDate?: string;
}