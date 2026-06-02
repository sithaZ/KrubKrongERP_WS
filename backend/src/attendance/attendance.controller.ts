import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { AttendanceService } from './attendance.service';
import { CheckInDto } from './dto/check-in.dto';
import { CheckOutDto } from './dto/check-out.dto';
import { UpdateAttendanceDto } from './dto/update-attendance.dto';
import { CreateShiftDto } from './dto/create-shift.dto';
import { UpdateShiftDto } from './dto/update-shift.dto';
import { AssignShiftDto } from './dto/assign-shift.dto';
import { AuthGuard } from '../auth/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';

@Controller('attendance')
@UseGuards(AuthGuard, RolesGuard)
@Roles(Role.MANAGER, Role.EMPLOYEE, Role.OWNER, Role.STAFF, Role.ADMIN)
export class AttendanceController {
  constructor(private readonly attendanceService: AttendanceService) {}

  // ───────────────────────────────────────────────────────────────────────────
  // SHIFT MANAGEMENT API
  // ───────────────────────────────────────────────────────────────────────────
  @Post('shifts')
  @Roles(Role.OWNER, Role.ADMIN)
  createShift(@Body() dto: CreateShiftDto) {
    return this.attendanceService.createShift(dto);
  }

  @Get('shifts')
  @Roles(Role.OWNER, Role.ADMIN, Role.MANAGER)
  findAllShifts() {
    return this.attendanceService.findAllShifts();
  }

  @Get('shifts/:id')
  @Roles(Role.OWNER, Role.ADMIN, Role.MANAGER)
  findShiftById(@Param('id') id: string) {
    return this.attendanceService.findShiftById(id);
  }

  @Patch('shifts/:id')
  @Roles(Role.OWNER, Role.ADMIN)
  updateShift(@Param('id') id: string, @Body() dto: UpdateShiftDto) {
    return this.attendanceService.updateShift(id, dto);
  }

  @Post('shifts/assign')
  @Roles(Role.OWNER, Role.ADMIN, Role.MANAGER)
  assignShift(@Body() dto: AssignShiftDto) {
    return this.attendanceService.assignShift(dto);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ATTENDANCE RECORDING API
  // ───────────────────────────────────────────────────────────────────────────
  @Post('check-in')
  checkIn(@Body() dto: CheckInDto, @Request() req: any) {
    return this.attendanceService.checkIn(dto, req.user);
  }

  @Post('check-out')
  checkOut(@Body() dto: CheckOutDto, @Request() req: any) {
    return this.attendanceService.checkOut(dto, req.user);
  }

  @Get('me')
  getMe(@Request() req: any) {
    return this.attendanceService.getMe(req.user);
  }

  @Get('my-today')
  getMyToday(@Request() req: any) {
    return this.attendanceService.getMyToday(req.user);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MANAGEMENT API & STATS
  // ───────────────────────────────────────────────────────────────────────────
  @Get()
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  findAll(@Query() query: any, @Request() req: any) {
    return this.attendanceService.findAll(query, req.user);
  }

  @Get('dashboard')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  getDashboardMetrics(@Request() req: any) {
    return this.attendanceService.getDashboardMetrics(req.user);
  }

  @Get('summary/:staffId')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN, Role.EMPLOYEE, Role.STAFF)
  getMonthlySummary(
    @Param('staffId') staffId: string,
    @Query('month') month: string,
    @Query('year') year: string,
    @Request() req: any,
  ) {
    const m = parseInt(month) || new Date().getMonth() + 1;
    const y = parseInt(year) || new Date().getFullYear();
    return this.attendanceService.getMonthlySummary(staffId, m, y, req.user);
  }

  @Get('payroll-summary/:staffId')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN, Role.EMPLOYEE, Role.STAFF)
  getPayrollSummary(
    @Param('staffId') staffId: string,
    @Query('month') month: string,
    @Query('year') year: string,
    @Request() req: any,
  ) {
    const m = parseInt(month) || new Date().getMonth() + 1;
    const y = parseInt(year) || new Date().getFullYear();
    return this.attendanceService.getPayrollSummary(staffId, m, y, req.user);
  }

  @Get('staff/:staffId')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  findByStaff(@Param('staffId') staffId: string, @Request() req: any) {
    return this.attendanceService.findByStaff(staffId, req.user);
  }

  @Get('employee/:employeeId')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN, Role.EMPLOYEE, Role.STAFF)
  findByEmployee(@Param('employeeId') employeeId: string, @Request() req: any) {
    return this.attendanceService.findByStaff(employeeId, req.user);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SHOP SETTINGS (DEFINED BEFORE PARAMETER WILD-CARD ROUTES)
  // ───────────────────────────────────────────────────────────────────────────
  @Get('shop-settings')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  getShopSettingsLegacy() {
    return this.attendanceService.getShopSettings();
  }

  @Get('shop/settings')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  getShopSettings() {
    return this.attendanceService.getShopSettings();
  }

  @Post('shop-settings')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  updateShopSettingsLegacy(@Body() dto: any) {
    return this.attendanceService.updateShopSettings(dto);
  }

  @Post('shop/settings')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  updateShopSettings(@Body() dto: any) {
    return this.attendanceService.updateShopSettings(dto);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WILDCARD PARAMETERIZED ATTENDANCE DETAILS (DEFINED LAST)
  // ───────────────────────────────────────────────────────────────────────────
  @Get(':id')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN, Role.EMPLOYEE, Role.STAFF)
  findOne(@Param('id') id: string, @Request() req: any) {
    return this.attendanceService.findOne(id, req.user);
  }

  @Patch(':id')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateAttendanceDto, @Request() req: any) {
    return this.attendanceService.update(id, dto, req.user);
  }
}
