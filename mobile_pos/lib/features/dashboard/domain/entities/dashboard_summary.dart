import 'package:equatable/equatable.dart';

class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.revenue,
    required this.today,
    required this.quickStats,
    required this.attendance,
    required this.recentActivities,
  });

  final RevenueBreakdown revenue;
  final TodayDashboardSnapshot today;
  final QuickStats quickStats;
  final AttendanceSummary attendance;
  final List<DashboardActivity> recentActivities;

  @override
  List<Object?> get props => [
        revenue,
        today,
        quickStats,
        attendance,
        recentActivities,
      ];
}

class RevenueBreakdown extends Equatable {
  const RevenueBreakdown({
    required this.daily,
    required this.monthly,
    required this.yearly,
  });

  final double daily;
  final double monthly;
  final double yearly;

  @override
  List<Object?> get props => [daily, monthly, yearly];
}

class TodayDashboardSnapshot extends Equatable {
  const TodayDashboardSnapshot({
    required this.grossSales,
    required this.orderCount,
    required this.averageOrderValue,
    required this.refunds,
  });

  final double grossSales;
  final int orderCount;
  final double averageOrderValue;
  final double refunds;

  @override
  List<Object?> get props => [grossSales, orderCount, averageOrderValue, refunds];
}

class QuickStats extends Equatable {
  const QuickStats({
    required this.totalProducts,
    required this.totalStaff,
    required this.presentStaff,
  });

  final int totalProducts;
  final int totalStaff;
  final int presentStaff;

  @override
  List<Object?> get props => [totalProducts, totalStaff, presentStaff];
}

class AttendanceSummary extends Equatable {
  const AttendanceSummary({
    required this.present,
    required this.late,
    required this.absent,
  });

  final int present;
  final int late;
  final int absent;

  @override
  List<Object?> get props => [present, late, absent];
}

class DashboardActivity extends Equatable {
  const DashboardActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.actorName,
    required this.occurredAt,
    this.amount,
    this.status,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final String actorName;
  final DateTime occurredAt;
  final double? amount;
  final String? status;

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        actorName,
        occurredAt,
        amount,
        status,
      ];
}

class StaffDashboardSummary extends Equatable {
  const StaffDashboardSummary({
    required this.hasCheckedIn,
    required this.shiftStatusLabel,
    required this.shiftDetail,
    required this.presentDaysThisMonth,
    required this.absentDaysThisMonth,
    required this.totalHoursThisMonth,
    required this.recentActivities,
  });

  final bool hasCheckedIn;
  final String shiftStatusLabel;
  final String shiftDetail;
  final double presentDaysThisMonth;
  final double absentDaysThisMonth;
  final double totalHoursThisMonth;
  final List<DashboardActivity> recentActivities;

  @override
  List<Object?> get props => [
        hasCheckedIn,
        shiftStatusLabel,
        shiftDetail,
        presentDaysThisMonth,
        absentDaysThisMonth,
        totalHoursThisMonth,
        recentActivities,
      ];
}
