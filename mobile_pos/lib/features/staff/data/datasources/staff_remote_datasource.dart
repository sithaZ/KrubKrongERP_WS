import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart' as app_errors;
import '../models/employee_model.dart';

abstract class StaffRemoteDataSource {
  Future<List<EmployeeModel>> getEmployees();
  Future<EmployeeModel> getEmployee(String id);
  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data);
  Future<EmployeeModel> updateEmployee(String id, Map<String, dynamic> data);
  Future<void> deactivateEmployee(String id);
}

class StaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  final Dio _client;

  StaffRemoteDataSourceImpl(this._client);

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final response = await _client.get('/employees');
      final data = response.data as List;
      return data.map((json) => EmployeeModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<EmployeeModel> getEmployee(String id) async {
    try {
      final response = await _client.get('/employees/$id');
      return EmployeeModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data) async {
    try {
      final response = await _client.post('/employees', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<EmployeeModel> updateEmployee(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch('/employees/$id', data: data);
      return EmployeeModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> deactivateEmployee(String id) async {
    try {
      await _client.patch('/employees/$id/deactivate');
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Exception _handleDioException(DioException e) {
    if (e.response?.statusCode == 401) {
      return app_errors.AuthException(e.response?.data['message'] ?? 'Unauthorized');
    }
    if (e.response?.statusCode == 400) {
      return app_errors.ValidationException(
        e.response?.data['message'] ?? 'Validation error',
        (e.response?.data['errors'] as Map?)?.cast<String, String>(),
      );
    }
    return app_errors.ServerException(e.response?.data['message'] ?? 'Server error');
  }
}
