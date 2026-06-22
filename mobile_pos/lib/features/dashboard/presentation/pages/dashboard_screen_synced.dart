import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/core.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final isStaff =
        user?.rawRole.toUpperCase() == 'EMPLOYEE' || user?.rawRole.toUpperCase() == 'STAFF';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(context.tr('Dashboard')),
      ),
      body: isStaff
          ? _StaffDashboardAsync(
              isDark: isDark,
              userName: user?.displayName ?? 'Staff',
            )
          : _ManagerDashboardAsync(isDark: isDark),
    );
  }
}

class _ManagerDashboardAsync extends ConsumerWidget {
  const _ManagerDashboardAsync({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(managerDashboardProvider);

    return asyncValue.when(
      data: (summary) => RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(managerDashboardProvider.future);
        },
        child: _ManagerDashboard(
          isDark: isDark,
          summary: summary,
        ),
      ),
      loading: () => const _DashboardLoadingState(),
      error: (error, _) => _DashboardErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(managerDashboardProvider),
      ),
    );
  }
}

class _StaffDashboardAsync extends ConsumerWidget {
  const _StaffDashboardAsync({
    required this.isDark,
    required this.userName,
  });

  final bool isDark;
  final String userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(staffDashboardProvider);

    return asyncValue.when(
      data: (summary) => RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(staffDashboardProvider.future);
        },
        child: _StaffDashboard(
          isDark: isDark,
          userName: userName,
          summary: summary,
        ),
      ),
      loading: () => const _DashboardLoadingState(),
      error: (error, _) => _DashboardErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(staffDashboardProvider),
      ),
    );
  }
}

class _ManagerDashboard extends StatelessWidget {
  const _ManagerDashboard({
    required this.isDark,
    required this.summary,
  });

  final bool isDark;
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _HeroSalesCard(today: summary.today),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Daily Revenue'),
        const SizedBox(height: 14),
        _RevenueSection(
          isDark: isDark,
          revenue: summary.revenue,
        ),
        const SizedBox(height: 28),
        SectionHeader(title: context.tr('Quick Stats')),
        const SizedBox(height: 14),
        _QuickStatsRow(
          isDark: isDark,
          stats: summary.quickStats,
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Staff Attendance Summary'),
        const SizedBox(height: 14),
        _StaffStatusRow(attendance: summary.attendance),
        const SizedBox(height: 28),
        SectionHeader(
          title: context.tr('Recent Activity'),
          action: TextButton(
            onPressed: () {},
            child: const Text('Live feed'),
          ),
        ),
        const SizedBox(height: 8),
        if (summary.recentActivities.isEmpty)
          _EmptyStateCard(
            isDark: isDark,
            message: 'No recent order or staff activity yet.',
          )
        else
          ...summary.recentActivities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActivityTile(
                activity: activity,
                isDark: isDark,
              ),
            ),
          ),
      ],
    );
  }
}

class _StaffDashboard extends StatelessWidget {
  const _StaffDashboard({
    required this.isDark,
    required this.userName,
    required this.summary,
  });

  final bool isDark;
  final String userName;
  final StaffDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFF1E35A5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.2),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: "Today's Shift Status"),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: summary.hasCheckedIn
                      ? AppTheme.success.withOpacity(0.08)
                      : AppTheme.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  summary.hasCheckedIn
                      ? Icons.work_history_outlined
                      : Icons.pending_actions_rounded,
                  color: summary.hasCheckedIn ? AppTheme.success : AppTheme.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.shiftStatusLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.shiftDetail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: summary.hasCheckedIn ? 'ACTIVE' : 'PENDING',
                color: summary.hasCheckedIn ? AppTheme.success : AppTheme.warning,
                backgroundColor: summary.hasCheckedIn
                    ? AppTheme.successSurface
                    : AppTheme.warningSurface,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StaffMetricCard(
              isDark: isDark,
              title: 'Attendance',
              value: summary.presentDaysThisMonth.toStringAsFixed(1),
              subtitle: 'Present days this month',
              icon: Icons.calendar_today_rounded,
              color: AppTheme.info,
            ),
            _StaffMetricCard(
              isDark: isDark,
              title: 'Work Hours',
              value: summary.totalHoursThisMonth.toStringAsFixed(1),
              subtitle: 'Hours recorded this month',
              icon: Icons.schedule_rounded,
              color: AppTheme.success,
            ),
            _StaffMetricCard(
              isDark: isDark,
              title: 'Absences',
              value: summary.absentDaysThisMonth.toStringAsFixed(1),
              subtitle: 'Days missed this month',
              icon: Icons.event_busy_rounded,
              color: AppTheme.error,
            ),
          ],
        ),
        const SizedBox(height: 28),
        SectionHeader(title: context.tr('Recent Activity')),
        const SizedBox(height: 12),
        if (summary.recentActivities.isEmpty)
          _EmptyStateCard(
            isDark: isDark,
            message: 'No attendance activity has been recorded yet.',
          )
        else
          ...summary.recentActivities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActivityTile(
                activity: activity,
                isDark: isDark,
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroSalesCard extends StatelessWidget {
  const _HeroSalesCard({
    required this.today,
  });

  final TodayDashboardSnapshot today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '\$');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF1A3BA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Gross Sales",
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withOpacity(0.75),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currency.format(today.grossSales),
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeroStat(
                title: 'Orders',
                value: '${today.orderCount}',
                theme: theme,
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              _HeroStat(
                title: 'Avg. Value',
                value: currency.format(today.averageOrderValue),
                theme: theme,
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              _HeroStat(
                title: 'Refunds',
                value: currency.format(today.refunds),
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueSection extends StatelessWidget {
  const _RevenueSection({
    required this.isDark,
    required this.revenue,
  });

  final bool isDark;
  final RevenueBreakdown revenue;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _RevenueCard(
          isDark: isDark,
          title: 'Today',
          value: revenue.daily,
          icon: Icons.today_rounded,
          color: AppTheme.primary,
        ),
        _RevenueCard(
          isDark: isDark,
          title: 'This Month',
          value: revenue.monthly,
          icon: Icons.calendar_view_month_rounded,
          color: AppTheme.info,
        ),
        _RevenueCard(
          isDark: isDark,
          title: 'This Year',
          value: revenue.yearly,
          icon: Icons.insights_rounded,
          color: AppTheme.success,
        ),
      ],
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({
    required this.isDark,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final bool isDark;
  final String title;
  final double value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardWidth = (MediaQuery.of(context).size.width - 52) / 2;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            NumberFormat.currency(symbol: '\$').format(value),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.title,
    required this.value,
    required this.theme,
  });

  final String title;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.isDark,
    required this.stats,
  });

  final bool isDark;
  final QuickStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.shopping_bag_rounded,
            label: 'Products',
            value: '${stats.totalProducts}',
            iconColor: AppTheme.info,
            bgColor: AppTheme.infoSurface,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.people_rounded,
            label: 'Staff',
            value: '${stats.totalStaff}',
            iconColor: AppTheme.warning,
            bgColor: AppTheme.warningSurface,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            label: 'Present',
            value: '${stats.presentStaff}',
            iconColor: AppTheme.success,
            bgColor: AppTheme.successSurface,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.bgColor,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color bgColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffStatusRow extends StatelessWidget {
  const _StaffStatusRow({
    required this.attendance,
  });

  final AttendanceSummary attendance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StaffStatusChip(
          icon: Icons.check_circle_rounded,
          label: '${attendance.present} Present',
          color: AppTheme.success,
        ),
        const SizedBox(width: 10),
        _StaffStatusChip(
          icon: Icons.schedule_rounded,
          label: '${attendance.late} Late',
          color: AppTheme.warning,
        ),
        const SizedBox(width: 10),
        _StaffStatusChip(
          icon: Icons.cancel_rounded,
          label: '${attendance.absent} Absent',
          color: AppTheme.error,
        ),
      ],
    );
  }
}

class _StaffStatusChip extends StatelessWidget {
  const _StaffStatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffMetricCard extends StatelessWidget {
  const _StaffMetricCard({
    required this.isDark,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final bool isDark;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardWidth = (MediaQuery.of(context).size.width - 52) / 2;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    required this.isDark,
  });

  final DashboardActivity activity;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = _activityVisual(activity.type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: visual.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(visual.icon, color: visual.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (activity.amount != null)
                Text(
                  NumberFormat.currency(symbol: '\$').format(activity.amount),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Text(
                _relativeTime(activity.occurredAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? AppTheme.darkTextDisabled : AppTheme.lightTextDisabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.isDark,
    required this.message,
  });

  final bool isDark;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
      ),
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 220),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Unable to load dashboard',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

_ActivityVisual _activityVisual(String type) {
  switch (type) {
    case 'order':
      return const _ActivityVisual(
        icon: Icons.receipt_long_rounded,
        background: AppTheme.primaryContainer,
        color: AppTheme.primary,
      );
    case 'check_out':
      return const _ActivityVisual(
        icon: Icons.logout_rounded,
        background: AppTheme.infoSurface,
        color: AppTheme.info,
      );
    default:
      return const _ActivityVisual(
        icon: Icons.person_add_rounded,
        background: AppTheme.successSurface,
        color: AppTheme.success,
      );
  }
}

String _relativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) {
    return 'Just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }
  return DateFormat('MMM d').format(dateTime);
}

class _ActivityVisual {
  const _ActivityVisual({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;
}
