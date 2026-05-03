import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart' as app_errors;
import '../../../../core/network/network_info.dart';
import '../datasources/staff_remote_datasource.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/staff_repository.dart';
import '../models/employee_model.dart';

class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  StaffRepositoryImpl(this._remoteDataSource, this._networkInfo);

  @override
  Future<Either<app_errors.Failure, List<Employee>>> getEmployees() async {
    if (!await _networkInfo.isConnected) {
      return left(const app_errors.NetworkFailure(message: 'No internet connection'));
    }

    try {
      final models = await _remoteDataSource.getEmployees();
      return right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return left(app_errors.ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<app_errors.Failure, Employee>> getEmployee(String id) async {
    try {
      final model = await _remoteDataSource.getEmployee(id);
      return right(model.toEntity());
    } catch (e) {
      return left(app_errors.ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<app_errors.Failure, Map<String, dynamic>>> createEmployee(Employee employee) async {
    try {
      final model = EmployeeModel(
        id: '',
        fullName: employee.fullName,
        email: employee.email,
        employeeCode: '',
        position: employee.position,
        department: employee.department,
        salaryType: employee.salaryType,
        baseSalary: employee.baseSalary,
        phone: employee.phone,
      );

      final response = await _remoteDataSource.createEmployee(model.toJson());
      final employeeEntity = EmployeeModel.fromJson(response['employee']).toEntity();
      final credentials = Map<String, dynamic>.from(response['credentials']);

      return right({
        'employee': employeeEntity,
        'credentials': credentials,
      });
    } on app_errors.ValidationException catch (e) {
      return left(app_errors.ValidationFailure(message: e.message, fieldErrors: e.fieldErrors));
    } catch (e) {
      return left(app_errors.ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<app_errors.Failure, Employee>> updateEmployee(Employee employee) async {
    try {
      final model = EmployeeModel(
        id: employee.id,
        fullName: employee.fullName,
        email: employee.email,
        employeeCode: employee.employeeCode,
        position: employee.position,
        department: employee.department,
        salaryType: employee.salaryType,
        baseSalary: employee.baseSalary,
        phone: employee.phone,
        isActive: employee.isActive,
      );

      final updatedModel = await _remoteDataSource.updateEmployee(employee.id, model.toJson());
      return right(updatedModel.toEntity());
    } catch (e) {
      return left(app_errors.ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<app_errors.Failure, void>> deactivateEmployee(String id) async {
    try {
      await _remoteDataSource.deactivateEmployee(id);
      return right(null);
    } catch (e) {
      return left(app_errors.ServerFailure(message: e.toString()));
    }
  }
}
