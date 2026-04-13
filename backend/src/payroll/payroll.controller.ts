import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { PayrollService } from './payroll.service';
import { GeneratePayrollDto } from './dto/generate-payroll.dto';

@Controller('payroll')
export class PayrollController {
  constructor(private readonly payrollService: PayrollService) {}

  // public for testing
  @Post('generate')
  generate(@Body() dto: GeneratePayrollDto) {
    return this.payrollService.generate(dto);
  }

  // public for testing
  @Get()
  findAll() {
    return this.payrollService.findAll();
  }

  // public for testing
  @Get('employee/:employeeId')
  findByEmployee(@Param('employeeId') employeeId: string) {
    return this.payrollService.findByEmployee(employeeId);
  }

  // public for testing
  @Get('employee/:employeeId/:month')
  findOneByEmployeeAndMonth(
    @Param('employeeId') employeeId: string,
    @Param('month') month: string,
  ) {
    return this.payrollService.findOneByEmployeeAndMonth(employeeId, month);
  }

  // public for testing
  @Patch(':id/finalize')
  finalize(@Param('id') id: string) {
    return this.payrollService.finalize(id);
  }
}