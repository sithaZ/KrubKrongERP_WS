import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { PayrollService } from './payroll.service';
import { GeneratePayrollDto } from './dto/generate-payroll.dto';
import { AuthGuard } from '../auth/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';

@Controller('payroll')
@UseGuards(AuthGuard, RolesGuard)
@Roles(Role.ADMIN, Role.MANAGER, Role.EMPLOYEE, Role.OWNER, Role.STAFF)
export class PayrollController {
  constructor(private readonly payrollService: PayrollService) {}

  @Post('generate')
  generate(@Body() dto: GeneratePayrollDto, @Request() req: any) {
    return this.payrollService.generate(dto, req.user);
  }

  @Get()
  findAll(@Request() req: any) {
    return this.payrollService.findAll(req.user);
  }

  @Get('employee/:employeeId')
  findByEmployee(@Param('employeeId') employeeId: string, @Request() req: any) {
    return this.payrollService.findByEmployee(employeeId, req.user);
  }

  @Get('employee/:employeeId/:month')
  findOneByEmployeeAndMonth(
    @Param('employeeId') employeeId: string,
    @Param('month') month: string,
    @Request() req: any,
  ) {
    return this.payrollService.findOneByEmployeeAndMonth(employeeId, month, req.user);
  }

  @Patch(':id/finalize')
  finalize(@Param('id') id: string, @Request() req: any) {
    return this.payrollService.finalize(id, req.user);
  }
}
