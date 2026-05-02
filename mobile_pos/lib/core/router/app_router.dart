import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../../features/order/presentation/pages/order_screen.dart';
import '../../features/pos/presentation/pages/pos_screen.dart';
import '../../features/product/presentation/pages/product_screen.dart';
import '../../features/staff/presentation/pages/staff_screen.dart';
import '../../presentation/widgets/app_navigation_shell.dart';

/// Route paths
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/';
  static const String pos = '/pos';
  static const String products = '/products';
  static const String staff = '/staff';
  static const String orders = '/orders';
  static const String profile = '/profile';
}

/// Navigation shell routes (routes with bottom nav)
final _shellRoutes = [
  AppRoutes.dashboard,
  AppRoutes.pos,
  AppRoutes.orders,
  AppRoutes.products,
  AppRoutes.staff,
];

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      // Don't redirect while checking auth status
      if (isLoading) return null;

      // Redirect unauthenticated users to login
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // Redirect authenticated users away from auth screens
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // Auth routes (no navigation shell)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      // Shell route with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Dashboard branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // POS branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.pos,
                builder: (context, state) => const PosScreen(),
              ),
            ],
          ),
          // Orders branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (context, state) => const OrderScreen(),
              ),
            ],
          ),
          // Products branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.products,
                builder: (context, state) => const ProductScreen(),
              ),
            ],
          ),
          // Staff branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.staff,
                builder: (context, state) => const StaffScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Auth refresh listenable for router
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this.ref) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }
  final ProviderRef<GoRouter> ref;
}
