import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../app/router/route_paths.dart';
import '../providers/staff_provider.dart';

/// Staff management screen
class StaffScreen extends ConsumerWidget {
  const StaffScreen({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final body = employeesAsync.when(
      data: (employees) {
        if (employees.isEmpty) {
          return EmptyStateWidget(
            message: 'No staff yet',
            subMessage: 'Add your first team member to get started.',
            icon: Icons.people_outline_rounded,
            action: ElevatedButton.icon(
              onPressed: () => context.push(AppRoutePaths.addStaff),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Staff'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(employeesProvider.future),
          color: AppTheme.primary,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: employees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final employee = employees[index];
              return _EmployeeCard(employee: employee, isDark: isDark);
            },
          ),
        );
      },
      loading: () => const AppLoadingIndicator(),
      error: (error, _) => AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.refresh(employeesProvider),
      ),
    );

    if (!showAppBar) return body;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutePaths.addStaff),
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Staff',
          ),
        ],
      ),
      body: body,
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee, required this.isDark});
  final dynamic employee;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = employee.isActive as bool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF1A3BA0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                (employee.fullName as String).substring(0, 1).toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        employee.fullName as String,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    StatusBadge(
                      label: isActive ? 'Active' : 'Inactive',
                      color: isActive ? AppTheme.success : AppTheme.error,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 12,
                      color: isDark ? AppTheme.darkTextDisabled : AppTheme.lightTextDisabled,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      employee.employeeCode as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.work_outline_rounded,
                      size: 12,
                      color: isDark ? AppTheme.darkTextDisabled : AppTheme.lightTextDisabled,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        employee.position as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Consumer(
            builder: (context, ref, _) {
              return IconButton(
                onPressed: () => _confirmDeactivation(context, ref),
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  size: 20,
                ),
                tooltip: 'Options',
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeactivation(BuildContext context, WidgetRef ref) {
    ModernAlert.show(
      context,
      title: 'Deactivate Staff',
      message: 'Are you sure you want to deactivate ${employee.fullName}? They will no longer be able to log in.',
      confirmLabel: 'Deactivate',
      cancelLabel: 'Cancel',
      icon: Icons.warning_amber_rounded,
      iconColor: AppTheme.error,
      onConfirm: () async {
        await ref.read(staffNotifierProvider.notifier).deactivateEmployee(employee.id);
        ref.refresh(employeesProvider);
      },
    );
  }
}
