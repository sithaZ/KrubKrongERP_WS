import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/app_constants.dart';
import '../storage/storage_service.dart';

/// REST API HTTP client configuration
class HttpClientConfig {
  HttpClientConfig(this._secureStorage);

  final SecureStorageService _secureStorage;
  late final Dio _dio;

  /// Initialize the Dio HTTP client
  void initialize() {
    final baseUrl = _sanitizeBaseUrl(
      dotenv.env[AppConstants.restApiEndpoint],
    );

    if (kDebugMode) {
      print('Resolved baseUrl: $baseUrl');
    }

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
      contentType: 'application/json',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LoggingInterceptor());
    }
  }

  /// Request interceptor to add auth token
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(AppConstants.authTokenKey);
    final sanitizedToken = token?.trim();
    if (sanitizedToken != null && sanitizedToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $sanitizedToken';
    }
    return handler.next(options);
  }

  /// Error interceptor for handling common errors
  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (kDebugMode) {
      print('HTTP Error: ${err.message}');
    }
    return handler.next(err);
  }

  Dio get client => _dio;

  String _sanitizeBaseUrl(String? rawBaseUrl) {
    var candidate = (rawBaseUrl ?? 'http://10.0.2.2:3000/api').trim();

    // Guard against accidental encoded/decoded leading spaces from copied env values.
    while (candidate.startsWith('%20')) {
      candidate = candidate.substring(3).trimLeft();
    }

    candidate = candidate.replaceFirst(RegExp(r'^\s+'), '');

    if (!candidate.startsWith('http://') && !candidate.startsWith('https://')) {
      candidate = 'http://$candidate';
    }

    final parsed = Uri.tryParse(candidate);
    if (parsed == null || parsed.host.isEmpty) {
      return 'http://10.0.2.2:3000/api';
    }

    return parsed.toString().replaceAll(RegExp(r'\/+$'), '');
  }
}

/// Simple logging interceptor for debug mode
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    print('BASE URL: ${options.baseUrl}');
    print('Headers: ${options.headers}');
    if (options.data != null) {
      print('Data: ${options.data}');
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    print('Data: ${response.data}');
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    print('Error: ${err.message}');
    if (err.response?.data != null) {
      print('Error Data: ${err.response?.data}');
    }
    return super.onError(err, handler);
  }
}
