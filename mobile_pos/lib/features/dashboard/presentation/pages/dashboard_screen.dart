import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../profile/presentation/widgets/profile_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../app/router/route_paths.dart';
import 'package:go_router/go_router.dart';

/// Role-based ERP Dashboard screen
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    // Identify role
    final isStaff = user?.rawRole.toUpperCase() == 'EMPLOYEE' || user?.rawRole.toUpperCase() == 'STAFF';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: isStaff
          ? _StaffDashboard(isDark: isDark, theme: theme, userName: user?.displayName ?? 'Staff')
          : _ManagerDashboard(isDark: isDark, theme: theme),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── MANAGER / OWNER DASHBOARD VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _ManagerDashboard extends StatelessWidget {
  const _ManagerDashboard({required this.isDark, required this.theme});
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Sales Card
          _HeroSalesCard(isDark: isDark, colorScheme: colorScheme, theme: theme),
          const SizedBox(height: 28),

          // Quick Stats Row
          const SectionHeader(title: 'Quick Stats'),
          const SizedBox(height: 14),
          _QuickStatsRow(isDark: isDark),
          const SizedBox(height: 28),

          // Live Status
          const SectionHeader(title: 'Staff Attendance Summary'),
          const SizedBox(height: 14),
          _StaffStatusRow(isDark: isDark),
          const SizedBox(height: 28),

          // Recent Activity
          SectionHeader(
            title: 'Recent Activity',
            action: TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ),
          const SizedBox(height: 8),
          _ActivityTile(
            icon: Icons.receipt_long_rounded,
            iconBgColor: AppTheme.primaryContainer,
            iconColor: AppTheme.primary,
            title: 'Order #1042',
            subtitle: '2 items · \$45.00',
            time: 'Just now',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _ActivityTile(
            icon: Icons.person_add_rounded,
            iconBgColor: AppTheme.successSurface,
            iconColor: AppTheme.success,
            title: 'Staff Check-in',
            subtitle: 'Sok Dara arrived',
            time: '15m ago',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _ActivityTile(
            icon: Icons.receipt_long_rounded,
            iconBgColor: AppTheme.primaryContainer,
            iconColor: AppTheme.primary,
            title: 'Order #1041',
            subtitle: '1 item · \$12.50',
            time: '1h ago',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ── Hero Sales Card
class _HeroSalesCard extends StatelessWidget {
  const _HeroSalesCard({
    required this.isDark,
    required this.colorScheme,
    required this.theme,
  });
  final bool isDark;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Gross Sales",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white.withOpacity(0.75),
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '+12.5%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '\$1,250.00',
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
              _HeroStat(title: 'Orders', value: '24', theme: theme),
              Container(width: 1, height: 32, color: Colors.white24),
              _HeroStat(title: 'Avg. Value', value: '\$52.08', theme: theme),
              Container(width: 1, height: 32, color: Colors.white24),
              _HeroStat(title: 'Refunds', value: '\$0.00', theme: theme),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.title, required this.value, required this.theme});
  final String title;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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

// ── Quick Stats Row
class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.shopping_bag_rounded,
            label: 'Products',
            value: '48',
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
            value: '6',
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
            value: '5',
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
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
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
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
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

// ── Staff Status Row
class _StaffStatusRow extends StatelessWidget {
  const _StaffStatusRow({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StaffStatusChip(icon: Icons.check_circle_rounded, label: '5 Present', color: AppTheme.success),
        const SizedBox(width: 10),
        _StaffStatusChip(icon: Icons.schedule_rounded, label: '1 Late', color: AppTheme.warning),
        const SizedBox(width: 10),
        _StaffStatusChip(icon: Icons.cancel_rounded, label: '0 Absent', color: AppTheme.error),
      ],
    );
  }
}

class _StaffStatusChip extends StatelessWidget {
  const _StaffStatusChip({required this.icon, required this.label, required this.color});
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

// ─────────────────────────────────────────────────────────────────────────────
// ── STAFF (EMPLOYEE) DASHBOARD VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _StaffDashboard extends StatelessWidget {
  const _StaffDashboard({
    required this.isDark,
    required this.theme,
    required this.userName,
  });

  final bool isDark;
  final ThemeData theme;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Greeting Card
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

          // ── Today's Shift Card
          const SectionHeader(title: 'Today’s Shift Status'),
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
                    color: AppTheme.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.work_history_outlined,
                    color: AppTheme.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift Active',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Clocked in at 08:30 AM',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: 'ON-SITE',
                  color: AppTheme.success,
                  backgroundColor: AppTheme.successSurface,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Personal Metrics Row
          Row(
            children: [
              Expanded(
                child: _PersonalStatCard(
                  title: 'Attendance',
                  value: '22 Days',
                  subtitle: 'Present this month',
                  icon: Icons.calendar_today_rounded,
                  color: AppTheme.info,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PersonalStatCard(
                  title: 'Est. Earnings',
                  value: '\$480.00',
                  subtitle: 'Payday: Jun 30',
                  icon: Icons.payments_outlined,
                  color: Colors.deepPurple,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Notifications/Pending Updates
          const SectionHeader(title: 'Recent Notifications'),
          const SizedBox(height: 12),
          _ActivityTile(
            icon: Icons.campaign_rounded,
            iconBgColor: AppTheme.infoSurface,
            iconColor: AppTheme.info,
            title: 'New Policy Update',
            subtitle: 'New check-in radius updated to 50m.',
            time: '2h ago',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _ActivityTile(
            icon: Icons.task_alt_rounded,
            iconBgColor: AppTheme.successSurface,
            iconColor: AppTheme.success,
            title: 'Payslip Available',
            subtitle: 'Your payslip for May is now ready to view.',
            time: '1d ago',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _PersonalStatCard extends StatelessWidget {
  const _PersonalStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
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
                  color: textSecondary,
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
              color: textSecondary,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity Tile
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isDark,
  });
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? AppTheme.darkTextDisabled : AppTheme.lightTextDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
