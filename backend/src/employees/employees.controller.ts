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
import { EmployeesService } from './employees.service';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { AuthGuard } from '../auth/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';

@Controller('employees')
@UseGuards(AuthGuard, RolesGuard)
@Roles(Role.ADMIN, Role.MANAGER, Role.OWNER)
export class EmployeesController {
  constructor(private readonly employeesService: EmployeesService) {}

  @Post()
  create(@Body() createEmployeeDto: CreateEmployeeDto, @Request() req: any) {
    return this.employeesService.create(createEmployeeDto, req.user);
  }

  @Get()
  findAll(@Request() req: any) {
    return this.employeesService.findAll(req.user);
  }

  @Get('active')
  findActive(@Request() req: any) {
    return this.employeesService.findActive(req.user);
  }

  @Get(':id')
  @Roles(Role.ADMIN, Role.MANAGER, Role.EMPLOYEE, Role.OWNER, Role.STAFF)
  findOne(@Param('id') id: string, @Request() req: any) {
    return this.employeesService.findOne(id, req.user);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateEmployeeDto: UpdateEmployeeDto, @Request() req: any) {
    return this.employeesService.update(id, updateEmployeeDto, req.user);
  }

  @Patch(':id/deactivate')
  deactivate(@Param('id') id: string, @Request() req: any) {
    return this.employeesService.deactivate(id, req.user);
  }
}
