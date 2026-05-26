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
import { CompaniesService } from './companies.service';
import { CreateCompanyDto } from './dto/create-company.dto';
import { UpdateCompanyDto } from './dto/update-company.dto';
import { CreateCompanyManagerDto } from './dto/create-company-manager.dto';
import { AuthGuard } from '../auth/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';

@Controller('shops')
@UseGuards(AuthGuard, RolesGuard)
@Roles(Role.ADMIN, Role.MANAGER, Role.OWNER)
export class CompaniesController {
  constructor(private readonly companiesService: CompaniesService) {}

  @Post()
  @Roles(Role.ADMIN)
  create(@Body() dto: CreateCompanyDto, @Request() req: any) {
    return this.companiesService.create(dto, req.user);
  }

  @Get()
  findAll(@Request() req: any) {
    return this.companiesService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string, @Request() req: any) {
    return this.companiesService.findOne(id);
  }

  @Patch(':id')
  @Roles(Role.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateCompanyDto, @Request() req: any) {
    return this.companiesService.update(id, dto);
  }

  @Post(':id/manager')
  @Roles(Role.ADMIN)
  createManager(
    @Param('id') id: string,
    @Body() dto: CreateCompanyManagerDto,
    @Request() req: any,
  ) {
    return this.companiesService.createManager(id, dto);
  }

  @Post(':id/owner')
  @Roles(Role.ADMIN)
  createOwner(
    @Param('id') id: string,
    @Body() dto: CreateCompanyManagerDto,
    @Request() req: any,
  ) {
    return this.companiesService.createOwner(id, dto);
  }
}
