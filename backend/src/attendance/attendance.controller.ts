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
import { AttendanceService } from './attendance.service';
import { CheckInDto } from './dto/check-in.dto';
import { CheckOutDto } from './dto/check-out.dto';
import { UpdateAttendanceDto } from './dto/update-attendance.dto';
import { AuthGuard } from '../auth/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';

@Controller('attendance')
@UseGuards(AuthGuard, RolesGuard)
@Roles(Role.MANAGER, Role.EMPLOYEE, Role.OWNER, Role.STAFF)
export class AttendanceController {
  constructor(private readonly attendanceService: AttendanceService) {}

  @Post('check-in')
  checkIn(@Body() dto: CheckInDto, @Request() req: any) {
    return this.attendanceService.checkIn(dto, req.user);
  }

  @Post('check-out')
  checkOut(@Body() dto: CheckOutDto, @Request() req: any) {
    return this.attendanceService.checkOut(dto, req.user);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateAttendanceDto, @Request() req: any) {
    return this.attendanceService.update(id, dto, req.user);
  }

  @Get()
  findAll(@Request() req: any) {
    return this.attendanceService.findAll(req.user);
  }

  @Get('employee/:employeeId')
  findByEmployee(@Param('employeeId') employeeId: string, @Request() req: any) {
    return this.attendanceService.findByEmployee(employeeId, req.user);
  }

  @Get('shop-settings')
  getShopSettings() {
    return this.attendanceService.getShopSettings();
  }

  @Post('shop-settings')
  @Roles(Role.MANAGER, Role.OWNER)
  updateShopSettings(@Body() dto: any) {
    return this.attendanceService.updateShopSettings(dto);
  }
}
