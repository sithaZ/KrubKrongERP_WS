import 'package:equatable/equatable.dart';

/// Base failure class for the application
abstract class Failure extends Equatable {

  const Failure({
    required this.message,
    this.code,
    this.stackTrace,
  });
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [message, code, stackTrace];
}

/// Server failures (5xx, GraphQL errors)
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

/// Network failures (no internet, timeout)
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

/// Authentication failures (401, 403, invalid credentials)
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

/// Validation failures (invalid input, form errors)
class ValidationFailure extends Failure {

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
    super.code,
    super.stackTrace,
  });
  final Map<String, String>? fieldErrors;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// Not found failures (404)
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

/// Cache/storage failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

/// Exception extension to convert exceptions to failures
extension ExceptionExtension on Exception {
  Failure toFailure({StackTrace? stackTrace}) {
    if (this is NetworkException) {
      return NetworkFailure(
        message: (this as NetworkException).message,
        stackTrace: stackTrace,
      );
    } else if (this is AuthException) {
      return AuthFailure(
        message: (this as AuthException).message,
        stackTrace: stackTrace,
      );
    } else if (this is ServerException) {
      return ServerFailure(
        message: (this as ServerException).message,
        stackTrace: stackTrace,
      );
    } else if (this is ValidationException) {
      return ValidationFailure(
        message: (this as ValidationException).message,
        fieldErrors: (this as ValidationException).fieldErrors,
        stackTrace: stackTrace,
      );
    } else if (this is CacheException) {
      return CacheFailure(
        message: (this as CacheException).message,
        stackTrace: stackTrace,
      );
    }
    return UnknownFailure(
      message: toString(),
      stackTrace: stackTrace,
    );
  }
}

/// Domain exceptions
class NetworkException implements Exception {
  NetworkException([this.message = 'Network error occurred']);
  final String message;
}

class AuthException implements Exception {
  AuthException([this.message = 'Authentication failed']);
  final String message;
}

class ServerException implements Exception {
  ServerException([this.message = 'Server error', this.statusCode]);
  final String message;
  final int? statusCode;
}

class ValidationException implements Exception {
  ValidationException([this.message = 'Validation failed', this.fieldErrors]);
  final String message;
  final Map<String, String>? fieldErrors;
}

class CacheException implements Exception {
  CacheException([this.message = 'Cache error occurred']);
  final String message;
}
