import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Login use case
/// Encapsulates the login business logic
class LoginUseCase implements UseCase<AuthTokens, LoginCredentials> {

  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthTokens>> call(LoginCredentials credentials) async {
    // Validate credentials before making API call
    if (credentials.email.isEmpty || credentials.password.isEmpty) {
      return left(const ValidationFailure(
        message: 'Email and password are required',
      ));
    }
    return await _repository.login(credentials);
  }
}

/// Register use case
class RegisterUseCase implements UseCase<AuthTokens, RegisterCredentials> {

  const RegisterUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthTokens>> call(RegisterCredentials credentials) async {
    if (credentials.name.isEmpty) {
      return left(const ValidationFailure(
        message: 'Name is required',
      ));
    }
    if (credentials.email.isEmpty) {
      return left(const ValidationFailure(
        message: 'Email is required',
      ));
    }
    if (credentials.password.length < 6) {
      return left(const ValidationFailure(
        message: 'Password must be at least 6 characters',
      ));
    }
    return await _repository.register(credentials);
  }
}

/// Get current user use case
class GetCurrentUserUseCase implements NoParamsUseCase<User> {

  const GetCurrentUserUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, User>> call() async {
    return await _repository.getCurrentUser();
  }
}

/// Logout use case
class LogoutUseCase implements NoParamsUseCase<void> {

  const LogoutUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call() async {
    return await _repository.logout();
  }
}

/// Check authentication status use case
class CheckAuthStatusUseCase implements UseCase<bool, NoParams> {

  const CheckAuthStatusUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    final isAuth = await _repository.isAuthenticated();
    return right(isAuth);
  }
}

/// Refresh token use case
class RefreshTokenUseCase implements NoParamsUseCase<AuthTokens> {

  const RefreshTokenUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthTokens>> call() async {
    return await _repository.refreshToken();
  }
}
