import { Controller, Get, Query, UseGuards } from '@nestjs/common';
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

  @Get('sales')
  @Roles(Role.ADMIN)
  getSalesData(
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    return this.dashboardService.getSalesData(dateFrom, dateTo);
  }

  @Get('top-products')
  @Roles(Role.ADMIN)
  getTopProducts(@Query('limit') limit: string = '10') {
    return this.dashboardService.getTopProducts(parseInt(limit));
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
