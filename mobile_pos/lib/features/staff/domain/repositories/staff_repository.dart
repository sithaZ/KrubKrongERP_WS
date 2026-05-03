import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart' as app_errors;
import '../entities/employee.dart';

abstract class StaffRepository {
  Future<Either<app_errors.Failure, List<Employee>>> getEmployees();
  Future<Either<app_errors.Failure, Employee>> getEmployee(String id);
  Future<Either<app_errors.Failure, Map<String, dynamic>>> createEmployee(Employee employee);
  Future<Either<app_errors.Failure, Employee>> updateEmployee(Employee employee);
  Future<Either<app_errors.Failure, void>> deactivateEmployee(String id);
}
