import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule } from '@nestjs/config';

import { AttendanceService } from './attendance.service';
import { AttendanceController } from './attendance.controller';
import { Attendance, AttendanceSchema } from './attendance.entity';
import { ShopSettings, ShopSettingsSchema } from './shop-settings.entity';
import { Shift, ShiftSchema } from './shift.entity';

import { Employee, EmployeeSchema } from '../employees/employee.entity';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    ConfigModule,
    AuthModule,
    MongooseModule.forFeature([
      { name: Attendance.name, schema: AttendanceSchema },
      { name: Employee.name, schema: EmployeeSchema },
      { name: ShopSettings.name, schema: ShopSettingsSchema },
      { name: Shift.name, schema: ShiftSchema },
    ]),
  ],
  controllers: [AttendanceController],
  providers: [AttendanceService],
  exports: [AttendanceService],
})
export class AttendanceModule {}