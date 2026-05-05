import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { PayrollService } from './payroll.service';
import { PayrollController } from './payroll.controller';
import { Payroll, PayrollSchema } from './payroll.entity';

import { Attendance, AttendanceSchema } from '../attendance/attendance.entity';
import { Employee, EmployeeSchema } from '../employees/employee.entity';

import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    AuthModule,
    MongooseModule.forFeature([
      { name: Payroll.name, schema: PayrollSchema },
      { name: Attendance.name, schema: AttendanceSchema },
      { name: Employee.name, schema: EmployeeSchema },
    ]),
  ],
  controllers: [PayrollController],
  providers: [PayrollService],
  exports: [PayrollService],
})
export class PayrollModule {}