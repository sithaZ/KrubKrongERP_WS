import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/route_paths.dart';
import '../../app/shell/employee_shell_screen.dart';
import '../../app/shell/manager_shell_screen.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutePaths.login,
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isLoginRoute = state.matchedLocation == AppRoutePaths.login;

      if (isLoading && authState.status == AuthStatus.initial) {
        return null;
      }

      if (!isAuthenticated) {
        return isLoginRoute ? null : AppRoutePaths.login;
      }

      final user = authState.user;
      if (user == null) {
        return null;
      }

      final targetRoute = _getHomeRouteForRole(user.role);
      if (targetRoute == null) {
        return AppRoutePaths.login;
      }

      if (isLoginRoute) {
        return targetRoute;
      }

      final isManagerRoute =
          state.matchedLocation.startsWith(AppRoutePaths.managerShell);
      final isEmployeeRoute =
          state.matchedLocation.startsWith(AppRoutePaths.employeeShell);

      if (user.role == UserRole.manager && !isManagerRoute) {
        return AppRoutePaths.managerShell;
      }

      if (user.role == UserRole.employee && !isEmployeeRoute) {
        return AppRoutePaths.employeeShell;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.managerShell,
        builder: (context, state) => const ManagerShellScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.employeeShell,
        builder: (context, state) => const EmployeeShellScreen(),
      ),
    ],
  );
});

String? _getHomeRouteForRole(UserRole? role) {
  switch (role) {
    case UserRole.manager:
      return AppRoutePaths.managerShell;
    case UserRole.employee:
      return AppRoutePaths.employeeShell;
    case null:
      return null;
  }
}

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this.ref) {
    ref.listen(authProvider, (previous, next) {
      final previousKey =
          '${previous?.status.name}:${previous?.user?.role?.name}';
      final nextKey = '${next.status.name}:${next.user?.role?.name}';

      if (previousKey != nextKey || previous?.isLoading != next.isLoading) {
        notifyListeners();
      }
    });
  }

  final ProviderRef<GoRouter> ref;
}
