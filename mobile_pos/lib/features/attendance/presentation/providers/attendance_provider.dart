import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/services/attendance_service.dart';

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final dio = ref.watch(httpClientInstanceProvider);
  return AttendanceService(dio);
});

final shopSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(attendanceServiceProvider);
  return await service.getShopSettings();
});

final attendanceRecordsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.watch(attendanceServiceProvider);
  return await service.getAllAttendance();
});

final employeeAttendanceHistoryProvider = FutureProvider.family<List<dynamic>, String>((ref, employeeId) async {
  final service = ref.watch(attendanceServiceProvider);
  return await service.getAttendanceHistory(employeeId);
});
