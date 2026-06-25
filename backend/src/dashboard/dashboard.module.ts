import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { DashboardService } from './dashboard.service';
import { DashboardController } from './dashboard.controller';
import { Order, OrderSchema } from '../orders/order.entity';
import { Employee, EmployeeSchema } from '../employees/employee.entity';
import { User, UserSchema } from '../users/user.entity';
import { Company, CompanySchema } from '../companies/company.entity';
import { Product, ProductSchema } from '../products/product.entity';
import { Attendance, AttendanceSchema } from '../attendance/attendance.entity';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    AuthModule,
    MongooseModule.forFeature([
      { name: Order.name, schema: OrderSchema },
      { name: Employee.name, schema: EmployeeSchema },
      { name: User.name, schema: UserSchema },
      { name: Company.name, schema: CompanySchema },
      { name: Product.name, schema: ProductSchema },
      { name: Attendance.name, schema: AttendanceSchema },
    ]),
  ],
  controllers: [DashboardController],
  providers: [DashboardService],
})
export class DashboardModule {}
