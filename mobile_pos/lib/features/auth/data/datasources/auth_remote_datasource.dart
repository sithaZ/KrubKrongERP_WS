import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart' as app_errors;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/storage_service.dart';
import '../models/user_model.dart';

/// Auth remote data source interface
abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<AuthResponseModel> register(
      String name, String email, String password, String? phone);
  Future<UserModel> getCurrentUser();
  Future<AuthTokensModel> refreshToken(String refreshToken);
  Future<void> logout();
}

/// REST API implementation of auth remote data source
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client, this._secureStorage);

  final Dio _client;
  final SecureStorageService _secureStorage;

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await _client.post(
        ApiConstants.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw app_errors.ServerException('Login failed: No data returned');
      }

      return AuthResponseModel.fromJson(data);
    } on app_errors.ServerException {
      rethrow;
    } on app_errors.AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<AuthResponseModel> register(
    String name,
    String email,
    String password,
    String? phone,
  ) async {
    try {
      final response = await _client.post(
        ApiConstants.registerEndpoint,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw app_errors.ServerException(
            'Registration failed: No data returned');
      }

      return AuthResponseModel.fromJson(data);
    } on app_errors.ServerException {
      rethrow;
    } on app_errors.ValidationException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _client.get(ApiConstants.getCurrentUserEndpoint);

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw app_errors.ServerException('Failed to get current user');
      }

      return UserModel.fromJson(data);
    } on app_errors.ServerException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<AuthTokensModel> refreshToken(String refreshToken) async {
    try {
      final response = await _client.post(
        ApiConstants.refreshTokenEndpoint,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw app_errors.AuthException('Token refresh failed');
      }

      return AuthTokensModel.fromJson(data);
    } on app_errors.AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.logoutEndpoint);
    } catch (e) {
      // Even if server logout fails, clear local session
    }

    // Clear all stored auth data
    await _secureStorage.delete(AppConstants.authTokenKey);
    await _secureStorage.delete(AppConstants.refreshTokenKey);
    await _secureStorage.delete(AppConstants.userDataKey);
  }

  /// Convert DioException to appropriate exception
  Never _handleDioException(DioException e) {
    if (e.response?.statusCode == 401) {
      throw app_errors.AuthException(
        e.response?.data['message'] ?? 'Unauthorized',
      );
    }
    if (e.response?.statusCode == 400) {
      final errors = e.response?.data['errors'] as Map<String, dynamic>?;
      throw app_errors.ValidationException(
        e.response?.data['message'] ?? 'Validation error',
        errors?.cast<String, String>(),
      );
    }
    if (e.response?.statusCode == 404) {
      throw app_errors.ServerException(
        e.response?.data['message'] ?? 'Not found',
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw app_errors.NetworkException(
        'Connection timeout. Please check your internet connection.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      throw app_errors.NetworkException(
        'Network connection failed. Please check your internet connection.',
      );
    }
    throw app_errors.ServerException(
      e.response?.data['message'] ?? 'Server error: ${e.message}',
    );
  }
}
