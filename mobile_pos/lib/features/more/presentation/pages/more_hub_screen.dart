import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/core.dart';
import '../../../../app/router/route_paths.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/widgets/profile_bottom_sheet.dart';

class MoreHubScreen extends ConsumerWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;

    // RBAC: check permissions
    final isOwner = user?.rawRole.toUpperCase() == 'OWNER' || user?.rawRole.toUpperCase() == 'ADMIN';
    final isManager = user?.rawRole.toUpperCase() == 'MANAGER';
    final isStaff = !isOwner && !isManager;

    // Define items lists depending on role
    final List<_MoreItem> items = [];

    if (isOwner) {
      items.addAll([
        _MoreItem(
          icon: Icons.people_outline_rounded,
          title: l10n.staffManagement,
          subtitle: l10n.staffManagementSubtitle,
          route: AppRoutePaths.staffList,
          color: AppTheme.primary,
        ),
        _MoreItem(
          icon: Icons.calendar_today_rounded,
          title: l10n.staffAttendance,
          subtitle: l10n.staffAttendanceSubtitle,
          route: AppRoutePaths.attendance,
          color: AppTheme.success,
        ),
        _MoreItem(
          icon: Icons.payments_outlined,
          title: l10n.payrollSummary,
          subtitle: l10n.payrollSummarySubtitle,
          route: AppRoutePaths.payroll,
          color: Colors.deepPurple,
        ),
        _MoreItem(
          icon: Icons.time_to_leave_outlined,
          title: l10n.leaveManagement,
          subtitle: l10n.leaveManagementSubtitle,
          route: AppRoutePaths.leaveManagement,
          color: Colors.teal,
        ),
        _MoreItem(
          icon: Icons.notifications_active_outlined,
          title: l10n.notifications,
          subtitle: l10n.notificationsSubtitle,
          route: AppRoutePaths.notifications,
          color: AppTheme.warning,
        ),
        _MoreItem(
          icon: Icons.settings_outlined,
          title: l10n.shopSettings,
          subtitle: l10n.shopSettingsSubtitle,
          route: AppRoutePaths.settings,
          color: Colors.blueGrey,
        ),
      ]);
    } else if (isManager) {
      items.addAll([
        _MoreItem(
          icon: Icons.people_outline_rounded,
          title: l10n.staffDirectory,
          subtitle: l10n.staffDirectorySubtitle,
          route: AppRoutePaths.staffList,
          color: AppTheme.primary,
        ),
        _MoreItem(
          icon: Icons.calendar_today_rounded,
          title: l10n.attendanceMonitor,
          subtitle: l10n.attendanceMonitorSubtitle,
          route: AppRoutePaths.attendance,
          color: AppTheme.success,
        ),
      ]);
    } else {
      // Employee / Staff
      items.addAll([
        _MoreItem(
          icon: Icons.today_outlined,
          title: l10n.myAttendance,
          subtitle: l10n.myAttendanceSubtitle,
          route: AppRoutePaths.attendance,
          color: AppTheme.success,
        ),
        _MoreItem(
          icon: Icons.payments_outlined,
          title: l10n.myPayroll,
          subtitle: l10n.myPayrollSubtitle,
          route: AppRoutePaths.payroll,
          color: Colors.deepPurple,
        ),
        _MoreItem(
          icon: Icons.notifications_active_outlined,
          title: l10n.myNotifications,
          subtitle: l10n.myNotificationsSubtitle,
          route: AppRoutePaths.notifications,
          color: AppTheme.warning,
        ),
        _MoreItem(
          icon: Icons.settings_outlined,
          title: l10n.appSettings,
          subtitle: l10n.appSettingsSubtitle,
          route: AppRoutePaths.settings,
          color: Colors.blueGrey,
        ),
      ]);
    }

    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l10n.more),
        actions: [
          GestureDetector(
            onTap: () => ProfileBottomSheet.show(context),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: const CircleAvatar(
                radius: 17,
                backgroundColor: AppTheme.primaryContainer,
                child: Icon(Icons.person_rounded, size: 18, color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ── Mini Profile Header ────────────────────
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
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF1A3BA0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user?.initials ?? 'U',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? l10n.userNameFallback,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user?.email ?? l10n.noEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: user?.roleLabel ?? 'ROLE',
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.primaryContainer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Menu List ──────────────────────────────
          Text(
            isStaff ? l10n.myAccount : l10n.managementAndAccount,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 56,
                color: border,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  onTap: () => context.push(item.route),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 19),
                  ),
                  title: Text(
                    item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    item.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? AppTheme.darkTextDisabled : AppTheme.lightTextDisabled,
                    size: 20,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;
}
