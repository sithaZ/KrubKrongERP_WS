import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { EmployeesService } from './employees/employees.service';
import { CreateEmployeeDto } from './employees/dto/create-employee.dto';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const service = app.get(EmployeesService);

  const dto: CreateEmployeeDto = {
    fullName: 'test1',
    email: 'test1@gmail.com',
    position: 'Staff',
    department: 'General',
    salaryType: 'monthly',
    baseSalary: 130.0,
    phone: '012613807',
    isActive: true,
    hireDate: undefined, // Flutter sends null, which becomes undefined/missing in JSON
  };

  try {
    console.log('Testing employee creation...');
    const result = await service.create(dto, {
      userId: 'debug-admin-user',
      role: 'ADMIN',
      companyId: null,
    });
    console.log('Success!', result);
  } catch (error) {
    console.error('DIAGNOSTIC ERROR CAUGHT:');
    console.error(error);
    if (error.response) {
      console.error('Response Data:', error.response);
    }
  } finally {
    await app.close();
  }
}

bootstrap();
