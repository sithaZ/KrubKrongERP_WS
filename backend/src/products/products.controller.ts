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
import { AuthGuard } from '../auth/auth.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';
import { RolesGuard } from '../common/guards/roles.guard';
import { AdjustStockDto } from './dto/adjust-stock.dto';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { ProductsService } from './products.service';

@Controller('products')
@UseGuards(AuthGuard, RolesGuard)
@Roles(Role.MANAGER, Role.EMPLOYEE, Role.OWNER, Role.ADMIN, Role.STAFF)
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  findAll(
    @Query('activeOnly') activeOnly: string,
    @Query('inStockOnly') inStockOnly: string,
    @Query('search') search: string | undefined,
    @Request() req: any,
  ) {
    return this.productsService.findAll(req.user, {
      activeOnly: activeOnly === 'true',
      inStockOnly: inStockOnly === 'true',
      search,
    });
  }

  @Get('low-stock')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  getLowStock(@Request() req: any) {
    return this.productsService.getLowStock(req.user);
  }

  @Get(':id')
  findOne(@Param('id') id: string, @Request() req: any) {
    return this.productsService.findOne(id, req.user);
  }

  @Post()
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  create(@Body() dto: CreateProductDto, @Request() req: any) {
    return this.productsService.create(dto, req.user);
  }

  @Patch(':id')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  update(
    @Param('id') id: string,
    @Body() dto: UpdateProductDto,
    @Request() req: any,
  ) {
    return this.productsService.update(id, dto, req.user);
  }

  @Patch(':id/stock')
  @Roles(Role.MANAGER, Role.OWNER, Role.ADMIN)
  adjustStock(
    @Param('id') id: string,
    @Body() dto: AdjustStockDto,
    @Request() req: any,
  ) {
    return this.productsService.adjustStock(id, dto, req.user);
  }
}
