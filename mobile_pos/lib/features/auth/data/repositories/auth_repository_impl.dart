import 'dart:async';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart' as app_errors;
import '../../../../core/network/network_info.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  ) {
    _checkInitialAuthState();
  }

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final _authStateController = StreamController<bool>.broadcast();

  void _checkInitialAuthState() async {
    final isAuth = await isAuthenticated();
    _authStateController.add(isAuth);
  }

  @override
  Future<Either<app_errors.Failure, AuthTokens>> login(
    LoginCredentials credentials,
  ) async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      print(
        'AuthRepositoryImpl.login: connectivity checker returned false; continuing with Dio login attempt.',
      );
    }

    try {
      final response = await _remoteDataSource.login(
        credentials.email,
        credentials.password,
      );

      if (!response.user.toEntity().hasSupportedRole) {
        await _localDataSource.clearCache();
        return left(const app_errors.AuthFailure(
          message: 'This app supports MANAGER and EMPLOYEE accounts only.',
        ));
      }

      await _localDataSource.cacheSession(response);
      _authStateController.add(true);

      return right(response.tokens.toEntity());
    } on app_errors.NetworkException catch (e, stackTrace) {
      return left(app_errors.NetworkFailure(
        message: e.message,
        stackTrace: stackTrace,
      ));
    } on app_errors.AuthException catch (e, stackTrace) {
      return left(app_errors.AuthFailure(
        message: e.message,
        stackTrace: stackTrace,
      ));
    } on app_errors.ServerException catch (e, stackTrace) {
      return left(app_errors.ServerFailure(
        message: e.message,
        code: e.statusCode?.toString(),
        stackTrace: stackTrace,
      ));
    } on app_errors.ValidationException catch (e, stackTrace) {
      return left(app_errors.ValidationFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
        stackTrace: stackTrace,
      ));
    } catch (e, stackTrace) {
      return left(app_errors.UnknownFailure(
        message: e.toString(),
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<app_errors.Failure, AuthTokens>> register(
    RegisterCredentials credentials,
  ) async {
    if (!await _networkInfo.isConnected) {
      return left(const app_errors.NetworkFailure(
        message: 'No internet connection. Please check your network.',
      ));
    }

    try {
      final response = await _remoteDataSource.register(
        credentials.name,
        credentials.email,
        credentials.password,
        credentials.phone,
      );

      if (!response.user.toEntity().hasSupportedRole) {
        await _localDataSource.clearCache();
        return left(const app_errors.AuthFailure(
          message: 'This app supports MANAGER and EMPLOYEE accounts only.',
        ));
      }

      await _localDataSource.cacheSession(response);
      _authStateController.add(true);

      return right(response.tokens.toEntity());
    } on app_errors.NetworkException catch (e, stackTrace) {
      return left(app_errors.NetworkFailure(
        message: e.message,
        stackTrace: stackTrace,
      ));
    } on app_errors.AuthException catch (e, stackTrace) {
      return left(app_errors.AuthFailure(
        message: e.message,
        stackTrace: stackTrace,
      ));
    } on app_errors.ServerException catch (e, stackTrace) {
      return left(app_errors.ServerFailure(
        message: e.message,
        code: e.statusCode?.toString(),
        stackTrace: stackTrace,
      ));
    } on app_errors.ValidationException catch (e, stackTrace) {
      return left(app_errors.ValidationFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
        stackTrace: stackTrace,
      ));
    } catch (e, stackTrace) {
      return left(app_errors.UnknownFailure(
        message: e.toString(),
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<app_errors.Failure, User>> getCurrentUser() async {
    try {
      final cachedUser = await _localDataSource.getLastUser();

      if (!await _networkInfo.isConnected) {
        if (cachedUser != null) {
          return right(cachedUser.toEntity());
        }

        return left(const app_errors.NetworkFailure(
          message: 'No internet connection and no cached user data.',
        ));
      }

      final user = await _remoteDataSource.getCurrentUser();

      if (!user.toEntity().hasSupportedRole) {
        await _localDataSource.clearCache();
        _authStateController.add(false);
        return left(const app_errors.AuthFailure(
          message: 'This app supports MANAGER and EMPLOYEE accounts only.',
        ));
      }

      await _localDataSource.cacheUser(user);
      return right(user.toEntity());
    } on app_errors.NetworkException catch (e, stackTrace) {
      return left(app_errors.NetworkFailure(
        message: e.message,
        stackTrace: stackTrace,
      ));
    } on app_errors.AuthException catch (e, stackTrace) {
      return left(app_errors.AuthFailure(
        message: e.message,
        stackTrace: stackTrace,
      ));
    } on app_errors.ServerException catch (e, stackTrace) {
      return left(app_errors.ServerFailure(
        message: e.message,
        code: e.statusCode?.toString(),
        stackTrace: stackTrace,
      ));
    } catch (e, stackTrace) {
      return left(app_errors.UnknownFailure(
        message: e.toString(),
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<app_errors.Failure, AuthTokens>> refreshToken() async {
    try {
      final refreshToken = await _localDataSource.getRefreshToken();
      if (refreshToken == null) {
        return left(const app_errors.AuthFailure(
          message: 'No refresh token available',
        ));
      }

      final tokens = await _remoteDataSource.refreshToken(refreshToken);
      await _localDataSource.cacheTokens(tokens);
      return right(tokens.toEntity());
    } on app_errors.AuthException catch (e, stackTrace) {
      return left(app_errors.AuthFailure(
        message: e.message,
        stackTrace: stackTrace,
      ));
    } on app_errors.ServerException catch (e, stackTrace) {
      return left(app_errors.ServerFailure(
        message: e.message,
        code: e.statusCode?.toString(),
        stackTrace: stackTrace,
      ));
    } catch (e, stackTrace) {
      return left(app_errors.UnknownFailure(
        message: e.toString(),
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<app_errors.Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      _authStateController.add(false);
      return right(null);
    } catch (e, stackTrace) {
      _authStateController.add(false);
      return left(app_errors.UnknownFailure(
        message: e.toString(),
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<app_errors.Failure, User>> updateProfile({
    String? name,
    String? phone,
    String? password,
    String? currentPassword,
  }) async {
    try {
      final user = await _remoteDataSource.updateProfile(
        name: name,
        phone: phone,
        password: password,
        currentPassword: currentPassword,
      );

      await _localDataSource.cacheUser(user);
      return right(user.toEntity());
    } on app_errors.NetworkException catch (e, stackTrace) {
      return left(app_errors.NetworkFailure(
        message: e.message,
        stackTrace: stackTrace,
      ));
    } on app_errors.AuthException catch (e, stackTrace) {
      return left(app_errors.AuthFailure(
        message: e.message,
        stackTrace: stackTrace,
      ));
    } on app_errors.ServerException catch (e, stackTrace) {
      return left(app_errors.ServerFailure(
        message: e.message,
        code: e.statusCode?.toString(),
        stackTrace: stackTrace,
      ));
    } catch (e, stackTrace) {
      return left(app_errors.UnknownFailure(
        message: e.toString(),
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _localDataSource.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Stream<bool> get authStateChanges => _authStateController.stream;
}
