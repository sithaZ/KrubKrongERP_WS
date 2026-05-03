import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../../features/order/presentation/pages/order_screen.dart';
import '../../features/pos/presentation/pages/pos_screen.dart';
import '../../features/product/presentation/pages/product_screen.dart';
import '../../features/staff/presentation/pages/staff_screen.dart';
import '../../features/staff/presentation/pages/add_staff_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/attendance/presentation/pages/attendance_screen.dart';
import '../../presentation/widgets/app_navigation_shell.dart';

/// Route paths
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String dashboard = '/';
  static const String pos = '/pos';
  static const String products = '/products';
  static const String staff = '/staff';
  static const String addStaff = '/staff/add';
  static const String orders = '/orders';
  static const String attendance = '/attendance';
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
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isAuthRoute = state.matchedLocation == AppRoutes.login;

      // Don't redirect while checking auth status (initial loading)
      if (isLoading && authState.status == AuthStatus.initial) return null;

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
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddStaffScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Attendance branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.attendance,
                builder: (context, state) => const AttendanceScreen(),
              ),
            ],
          ),
          // Profile branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
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
