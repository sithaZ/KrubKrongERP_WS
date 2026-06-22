import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/route_paths.dart';
import '../../app/shell/employee_shell_screen.dart';
import '../../app/shell/manager_shell_screen.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/staff/presentation/pages/add_staff_screen.dart';
import '../../features/staff/presentation/pages/staff_screen.dart';
import '../../features/attendance/presentation/pages/attendance_screen.dart';
import '../../features/attendance/presentation/pages/attendance_detail_screen.dart';
import '../../features/order/presentation/pages/order_screen.dart';
import '../../features/inventory/presentation/pages/inventory_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../widgets/placeholder_screen.dart';

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

      final location = state.uri.path;
      final isManagerRoute =
          location.startsWith(AppRoutePaths.managerShell) ||
          location.startsWith(AppRoutePaths.addStaff) ||
          location.startsWith(AppRoutePaths.staffList) ||
          location.startsWith(AppRoutePaths.attendance) ||
          location.startsWith(AppRoutePaths.payroll) ||
          location.startsWith(AppRoutePaths.settings) ||
          location.startsWith(AppRoutePaths.products) ||
          location.startsWith(AppRoutePaths.suppliers) ||
          location.startsWith(AppRoutePaths.purchaseOrders) ||
          location.startsWith(AppRoutePaths.reports) ||
          location.startsWith(AppRoutePaths.expenses) ||
          location.startsWith(AppRoutePaths.leaveManagement) ||
          location.startsWith(AppRoutePaths.notifications) ||
          location.startsWith(AppRoutePaths.inventory) ||
          location.startsWith(AppRoutePaths.orders);
          
      final isEmployeeRoute =
          location.startsWith(AppRoutePaths.employeeShell) ||
          location.startsWith(AppRoutePaths.attendance) ||
          location.startsWith(AppRoutePaths.payroll) ||
          location.startsWith(AppRoutePaths.notifications) ||
          location.startsWith(AppRoutePaths.settings) ||
          location.startsWith(AppRoutePaths.leaveManagement);

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
      GoRoute(
        path: AppRoutePaths.addStaff,
        builder: (context, state) => const AddStaffScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.staffList,
        builder: (context, state) => const StaffScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.attendance,
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.attendanceDetail,
        builder: (context, state) {
          final record = state.extra as Map<String, dynamic>;
          return AttendanceDetailScreen(record: record);
        },
      ),
      GoRoute(
        path: AppRoutePaths.products,
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.suppliers,
        builder: (context, state) => const ErpPlaceholderScreen(
          title: 'Supplier Management',
          description: 'This feature will be available in a future release.',
          icon: Icons.local_shipping_outlined,
        ),
      ),
      GoRoute(
        path: AppRoutePaths.purchaseOrders,
        builder: (context, state) => const ErpPlaceholderScreen(
          title: 'Purchase Orders',
          description: 'This feature will be available in a future release.',
          icon: Icons.shopping_cart_checkout_outlined,
        ),
      ),
      GoRoute(
        path: AppRoutePaths.reports,
        builder: (context, state) => const ErpPlaceholderScreen(
          title: 'Business Reports',
          description: 'This feature will be available in a future release.',
          icon: Icons.analytics_outlined,
        ),
      ),
      GoRoute(
        path: AppRoutePaths.expenses,
        builder: (context, state) => const ErpPlaceholderScreen(
          title: 'Expense Management',
          description: 'This feature will be available in a future release.',
          icon: Icons.account_balance_wallet_outlined,
        ),
      ),
      GoRoute(
        path: AppRoutePaths.leaveManagement,
        builder: (context, state) => const ErpPlaceholderScreen(
          title: 'Leave Management',
          description: 'This feature will be available in a future release.',
          icon: Icons.time_to_leave_outlined,
        ),
      ),
      GoRoute(
        path: AppRoutePaths.notifications,
        builder: (context, state) => const ErpPlaceholderScreen(
          title: 'Notifications',
          description: 'This feature will be available in a future release.',
          icon: Icons.notifications_active_outlined,
        ),
      ),
      GoRoute(
        path: AppRoutePaths.payroll,
        builder: (context, state) => const ErpPlaceholderScreen(
          title: 'Payroll Management',
          description: 'This feature will be available in a future release.',
          icon: Icons.payments_outlined,
        ),
      ),
      GoRoute(
        path: AppRoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.inventory,
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.orders,
        builder: (context, state) => const OrderScreen(),
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
