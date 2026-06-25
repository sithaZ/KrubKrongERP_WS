import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Delete,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';
import { RolesGuard } from '../common/guards/roles.guard';
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { AuthGuard } from '../auth/auth.guard';
import { OrderStatus } from './order.entity';

@Controller('orders')
@UseGuards(AuthGuard, RolesGuard)
@Roles(Role.MANAGER, Role.EMPLOYEE, Role.OWNER, Role.ADMIN, Role.STAFF)
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  createOrder(@Body() createOrderDto: CreateOrderDto, @Request() req: any) {
    return this.ordersService.createOrder(createOrderDto, req.user);
  }

  @Get()
  getOrders(
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
    @Query('status') status?: OrderStatus,
    @Query('cashierId') cashierId?: string,
    @Request() req?: any,
  ) {
    return this.ordersService.getOrders(req.user, dateFrom, dateTo, status, cashierId);
  }

  @Get('performance/summary')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  getPerformanceSummary(
    @Query('dateFrom') dateFrom: string | undefined,
    @Query('dateTo') dateTo: string | undefined,
    @Request() req: any,
  ) {
    return this.ordersService.getPerformanceSummary(req.user, dateFrom, dateTo);
  }

  @Get(':id')
  getOrderById(@Param('id') id: string, @Request() req: any) {
    return this.ordersService.getOrderById(id, req.user);
  }

  @Patch(':id/status')
  updateOrderStatus(
    @Param('id') id: string,
    @Body() updateOrderStatusDto: UpdateOrderStatusDto,
    @Request() req: any,
  ) {
    return this.ordersService.updateOrderStatus(id, updateOrderStatusDto, req.user);
  }

  @Delete(':id')
  deleteOrder(@Param('id') id: string, @Request() req: any) {
    return this.ordersService.deleteOrder(id, req.user);
  }
}
