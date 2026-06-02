import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Auth repository interface (contract)
/// The domain layer defines what operations are needed, not how they are implemented
abstract class AuthRepository {
  /// Login with email and password
  /// Returns [AuthTokens] on success
  Future<Either<Failure, AuthTokens>> login(LoginCredentials credentials);

  /// Register a new user
  /// Returns [AuthTokens] on success
  Future<Either<Failure, AuthTokens>> register(RegisterCredentials credentials);

  /// Get currently authenticated user
  /// Returns [User] on success
  Future<Either<Failure, User>> getCurrentUser();

  /// Refresh access token using refresh token
  Future<Either<Failure, AuthTokens>> refreshToken();

  /// Logout user and clear session
  Future<Either<Failure, void>> logout();

  /// Update user profile details
  Future<Either<Failure, User>> updateProfile({String? name, String? phone, String? password, String? currentPassword});

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Stream of auth state changes
  Stream<bool> get authStateChanges;
}
