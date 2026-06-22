import { Controller, Get, Query, Request, UseGuards } from '@nestjs/common';
import { DashboardService } from './dashboard.service';
import { AuthGuard } from '../auth/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';

@Controller('dashboard')
@UseGuards(AuthGuard, RolesGuard)
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('stats')
  @Roles(Role.ADMIN)
  getStats() {
    return this.dashboardService.getStats();
  }

  @Get('shop-summary')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  getShopSummary(@Request() req: any) {
    return this.dashboardService.getShopSummary(req.user);
  }

  @Get('sales')
  @Roles(Role.ADMIN)
  getSalesData(
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    return this.dashboardService.getSalesData(dateFrom, dateTo);
  }

  @Get('revenue')
  @Roles(Role.ADMIN)
  getRevenueData(
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    return this.dashboardService.getRevenueData(dateFrom, dateTo);
  }
}
