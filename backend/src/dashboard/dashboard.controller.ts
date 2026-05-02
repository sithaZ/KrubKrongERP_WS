import { Controller, Get, Query } from '@nestjs/common';
import { DashboardService } from './dashboard.service';

@Controller('dashboard')
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('stats')
  getStats() {
    return this.dashboardService.getStats();
  }

  @Get('sales')
  getSalesData(
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    return this.dashboardService.getSalesData(dateFrom, dateTo);
  }

  @Get('top-products')
  getTopProducts(@Query('limit') limit: string = '10') {
    return this.dashboardService.getTopProducts(parseInt(limit));
  }

  @Get('revenue')
  getRevenueData(
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    return this.dashboardService.getRevenueData(dateFrom, dateTo);
  }
}
