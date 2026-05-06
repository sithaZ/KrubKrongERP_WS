import 'dart:io';
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
      print('Before GET /employees');
      print('Request headers before GET /employees: ${_client.options.headers}');
      final response = await _client.get('/employees');
      print('Dio status code: ${response.statusCode}');
      print('Response request headers: ${response.requestOptions.headers}');
      print('Response data: ${response.data}');
      final data = response.data as List;
      return data.map((json) => EmployeeModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Dio error status: ${e.response?.statusCode}');
      print('Dio error request headers: ${e.requestOptions.headers}');
      print('Dio error response: ${e.response?.data}');
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
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.error is SocketException) {
      return app_errors.NetworkException('No internet connection');
    }

    if (e.response?.statusCode == 401) {
      return app_errors.AuthException('Please log in again');
    }
    if (e.response?.statusCode == 403) {
      return app_errors.AuthException('Access denied');
    }
    if (e.response?.statusCode == 400) {
      return app_errors.ValidationException(
        _extractMessage(e.response?.data, fallback: 'Validation error'),
        (e.response?.data['errors'] as Map?)?.cast<String, String>(),
      );
    }

    return app_errors.ServerException(
      _extractMessage(e.response?.data, fallback: 'Server error'),
      e.response?.statusCode,
    );
  }

  String _extractMessage(dynamic data, {required String fallback}) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return fallback;
  }
}
