import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart' as app_errors;
import '../../../../core/providers/core_providers.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../data/datasources/auth_local_datasource.dart';
import 'package:erp_mobile/core/storage/storage_service.dart';

/// ==================== Repository Provider ====================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(httpClientInstanceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  final remoteDataSource = AuthRemoteDataSourceImpl(client, secureStorage);
  final localDataSource = AuthLocalDataSourceImpl(secureStorage);

  return AuthRepositoryImpl(
    remoteDataSource,
    localDataSource,
    networkInfo,
  );
});

/// ==================== Use Case Providers ====================

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final checkAuthStatusUseCaseProvider = Provider<CheckAuthStatusUseCase>((ref) {
  return CheckAuthStatusUseCase(ref.watch(authRepositoryProvider));
});

/// ==================== Auth State Provider ====================

/// Auth state representing the authentication status
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

/// Auth state class
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.failure,
    this.isLoading = false,
  });
  final AuthStatus status;
  final User? user;
  final app_errors.Failure? failure;
  final bool isLoading;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    app_errors.Failure? failure,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      failure: failure,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
}

/// Auth state notifier - manages authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(
    this._loginUseCase,
    this._registerUseCase,
    this._getCurrentUserUseCase,
    this._logoutUseCase,
    this._checkAuthStatusUseCase,
    this._authRepository,
  ) : super(const AuthState()) {
    // Check auth status on initialization
    checkAuthStatus();
  }
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final AuthRepository _authRepository;

  /// Check if user is authenticated
  Future<void> checkAuthStatus() async {
    state = state.copyWith(
      status: state.status == AuthStatus.initial ? AuthStatus.loading : state.status,
      isLoading: true,
    );

    final result = await _checkAuthStatusUseCase(const NoParams());

    result.fold(
      (failure) {
        // If we are already authenticated, don't logout on check failure (might be network)
        if (state.status == AuthStatus.authenticated) {
          state = state.copyWith(isLoading: false);
          return;
        }
        
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          failure: failure,
        );
      },
      (isAuthenticated) async {
        if (isAuthenticated) {
          // If we are already authenticated and have a user, we can skip fetching user again or do it silently
          if (state.status == AuthStatus.authenticated && state.user != null) {
            state = state.copyWith(isLoading: false);
            // Optionally refresh user data silently
            _getCurrentUserUseCase().then((userResult) {
               userResult.fold((_) {}, (user) => state = state.copyWith(user: user));
            });
            return;
          }

          // Get current user data
          final userResult = await _getCurrentUserUseCase();
          userResult.fold(
            (failure) {
              // If already authenticated, stay that way on failure
              if (state.status == AuthStatus.authenticated) {
                state = state.copyWith(isLoading: false);
              } else {
                state = state.copyWith(
                  status: AuthStatus.unauthenticated,
                  isLoading: false,
                );
              }
            },
            (user) => state = state.copyWith(
              status: AuthStatus.authenticated,
              user: user,
              isLoading: false,
            ),
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            isLoading: false,
          );
        }
      },
    );
  }

  /// Login user
  Future<void> login(String email, String password) async {
    state = state.copyWith(
        status: AuthStatus.loading, isLoading: true, failure: null);

    final credentials = LoginCredentials(email: email, password: password);
    final result = await _loginUseCase(credentials);

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        isLoading: false,
        failure: failure,
      ),
      (tokens) async {
        // Fetch user data after successful login
        final userResult = await _getCurrentUserUseCase();
        userResult.fold(
          (failure) => state = state.copyWith(
            status: AuthStatus.authenticated,
            isLoading: false,
          ),
          (user) => state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            isLoading: false,
          ),
        );
      },
    );
  }

  /// Register new user
  Future<void> register(
      String name, String email, String password, String? phone) async {
    state = state.copyWith(
        status: AuthStatus.loading, isLoading: true, failure: null);

    final credentials = RegisterCredentials(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
    final result = await _registerUseCase(credentials);

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        isLoading: false,
        failure: failure,
      ),
      (tokens) async {
        final userResult = await _getCurrentUserUseCase();
        userResult.fold(
          (failure) => state = state.copyWith(
            status: AuthStatus.authenticated,
            isLoading: false,
          ),
          (user) => state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            isLoading: false,
          ),
        );
      },
    );
  }

  /// Logout user
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading, isLoading: true);

    final result = await _logoutUseCase();

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      ),
      (_) => state = const AuthState(status: AuthStatus.unauthenticated),
    );
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    final result = await _getCurrentUserUseCase();
    result.fold(
      (failure) {}, // Silently fail, keep existing user data
      (user) => state = state.copyWith(user: user),
    );
  }

  /// Clear error state
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(status: AuthStatus.unauthenticated, failure: null);
    }
  }
}

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(loginUseCaseProvider),
    ref.watch(registerUseCaseProvider),
    ref.watch(getCurrentUserUseCaseProvider),
    ref.watch(logoutUseCaseProvider),
    ref.watch(checkAuthStatusUseCaseProvider),
    ref.watch(authRepositoryProvider),
  );
});

/// Auth state changes stream provider
final authStateStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Current user provider (derived from auth state)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Is authenticated provider (derived from auth state)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
