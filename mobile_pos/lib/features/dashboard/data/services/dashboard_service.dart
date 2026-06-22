import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/dashboard_summary.dart';

class DashboardService {
  DashboardService(this._client);

  final Dio _client;

  Future<DashboardSummary> getManagerDashboardSummary() async {
    try {
      final response = await _client.get('/dashboard/shop-summary');
      final data = response.data as Map<String, dynamic>;

      return DashboardSummary(
        revenue: _parseRevenue(data['revenue']),
        today: _parseToday(data['today']),
        quickStats: _parseQuickStats(data['quickStats']),
        attendance: _parseAttendance(data['attendance']),
        recentActivities: _parseActivities(data['recentActivities']),
      );
    } on DioException catch (e) {
      throw ServerFailure(
        message: e.response?.data['message'] ?? 'Failed to load dashboard',
      );
    }
  }

  Future<StaffDashboardSummary> getStaffDashboardSummary(String userId) async {
    try {
      final results = await Future.wait([
        _client.get('/attendance/my-today'),
        _client.get(
          '/attendance/payroll-summary/$userId',
          queryParameters: {
            'month': DateTime.now().month,
            'year': DateTime.now().year,
          },
        ),
        _client.get('/attendance/me'),
      ]);

      final todayData = results[0].data as Map<String, dynamic>;
      final payrollData = results[1].data as Map<String, dynamic>;
      final historyData = (results[2].data as List)
          .whereType<Map<String, dynamic>>()
          .toList();

      final checkedIn = todayData['checkedIn'] != false &&
          (todayData['checkInTime'] != null || todayData['checkIn'] != null);
      final checkedOut = todayData['checkOutTime'] != null || todayData['checkOut'] != null;
      final attendanceStatus =
          (todayData['attendanceStatus'] ?? todayData['status'] ?? 'ABSENT')
              .toString()
              .toUpperCase();
      final checkInTime = _parseDateTime(todayData['checkInTime'] ?? todayData['checkIn']);
      final checkOutTime = _parseDateTime(todayData['checkOutTime'] ?? todayData['checkOut']);

      final recentActivities = historyData.take(6).map((record) {
        final recordCheckOut = _parseDateTime(record['checkOutTime'] ?? record['checkOut']);
        final recordCheckIn = _parseDateTime(record['checkInTime'] ?? record['checkIn']);
        final recordStatus =
            (record['attendanceStatus'] ?? record['status'] ?? '').toString();
        final isCheckOut = recordCheckOut != null;
        final isLate = recordStatus.toUpperCase() == 'LATE';

        return DashboardActivity(
          id: (record['_id'] ?? record['id'] ?? '').toString(),
          type: isCheckOut ? 'check_out' : 'check_in',
          title: isCheckOut
              ? 'Checked out'
              : isLate
                  ? 'Checked in late'
                  : 'Checked in',
          description: isCheckOut
              ? 'You finished your shift for the day.'
              : isLate
                  ? 'Your check-in was marked late.'
                  : 'Your shift started successfully.',
          actorName: 'You',
          occurredAt: recordCheckOut ??
              recordCheckIn ??
              _parseDateTime(record['updatedAt']) ??
              DateTime.now(),
          status: recordStatus,
        );
      }).toList();

      return StaffDashboardSummary(
        hasCheckedIn: checkedIn,
        shiftStatusLabel: checkedOut
            ? 'Shift Completed'
            : checkedIn
                ? attendanceStatus == 'LATE'
                    ? 'Checked In Late'
                    : 'Shift Active'
                : 'Not Checked In',
        shiftDetail: checkedOut
            ? 'Checked out at ${_formatTime(checkOutTime)}'
            : checkedIn
                ? 'Checked in at ${_formatTime(checkInTime)}'
                : 'No attendance record for today yet',
        presentDaysThisMonth:
            (payrollData['attendedDays'] as num?)?.toDouble() ?? 0,
        absentDaysThisMonth:
            (payrollData['absentDays'] as num?)?.toDouble() ?? 0,
        totalHoursThisMonth:
            (payrollData['totalHours'] as num?)?.toDouble() ?? 0,
        recentActivities: recentActivities,
      );
    } on DioException catch (e) {
      throw ServerFailure(
        message: e.response?.data['message'] ?? 'Failed to load staff dashboard',
      );
    }
  }

  RevenueBreakdown _parseRevenue(dynamic raw) {
    final data = (raw as Map?)?.cast<String, dynamic>() ?? const {};
    return RevenueBreakdown(
      daily: (data['daily'] as num?)?.toDouble() ?? 0,
      monthly: (data['monthly'] as num?)?.toDouble() ?? 0,
      yearly: (data['yearly'] as num?)?.toDouble() ?? 0,
    );
  }

  TodayDashboardSnapshot _parseToday(dynamic raw) {
    final data = (raw as Map?)?.cast<String, dynamic>() ?? const {};
    return TodayDashboardSnapshot(
      grossSales: (data['grossSales'] as num?)?.toDouble() ?? 0,
      orderCount: (data['orderCount'] as num?)?.toInt() ?? 0,
      averageOrderValue: (data['averageOrderValue'] as num?)?.toDouble() ?? 0,
      refunds: (data['refunds'] as num?)?.toDouble() ?? 0,
    );
  }

  QuickStats _parseQuickStats(dynamic raw) {
    final data = (raw as Map?)?.cast<String, dynamic>() ?? const {};
    return QuickStats(
      totalProducts: (data['totalProducts'] as num?)?.toInt() ?? 0,
      totalStaff: (data['totalStaff'] as num?)?.toInt() ?? 0,
      presentStaff: (data['presentStaff'] as num?)?.toInt() ?? 0,
    );
  }

  AttendanceSummary _parseAttendance(dynamic raw) {
    final data = (raw as Map?)?.cast<String, dynamic>() ?? const {};
    return AttendanceSummary(
      present: (data['present'] as num?)?.toInt() ?? 0,
      late: (data['late'] as num?)?.toInt() ?? 0,
      absent: (data['absent'] as num?)?.toInt() ?? 0,
    );
  }

  List<DashboardActivity> _parseActivities(dynamic raw) {
    final items = (raw as List?)?.whereType<Map>().toList() ?? const [];

    return items.map((item) {
      final data = item.cast<String, dynamic>();
      return DashboardActivity(
        id: (data['id'] ?? '').toString(),
        type: (data['type'] ?? '').toString(),
        title: (data['title'] ?? '').toString(),
        description: (data['description'] ?? '').toString(),
        actorName: (data['actorName'] ?? '').toString(),
        occurredAt: _parseDateTime(data['occurredAt']) ?? DateTime.now(),
        amount: (data['amount'] as num?)?.toDouble(),
        status: data['status']?.toString(),
      );
    }).toList();
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return '--:--';
    }

    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
