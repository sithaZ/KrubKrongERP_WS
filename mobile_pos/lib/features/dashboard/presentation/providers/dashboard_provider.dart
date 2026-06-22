import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/dashboard_service.dart';
import '../../domain/entities/dashboard_summary.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final dio = ref.watch(httpClientInstanceProvider);
  return DashboardService(dio);
});

final managerDashboardProvider = FutureProvider<DashboardSummary>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getManagerDashboardSummary();
});

final staffDashboardProvider = FutureProvider<StaffDashboardSummary>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    throw Exception('User not found');
  }

  return service.getStaffDashboardSummary(user.id);
});
