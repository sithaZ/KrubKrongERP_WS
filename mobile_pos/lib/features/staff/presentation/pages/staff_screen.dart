import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/common_widgets.dart';
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

    final body = employeesAsync.when(
        data: (employees) {
          if (employees.isEmpty) {
            return EmptyStateWidget(
              message: 'No staff members yet',
              subMessage: 'Add your first employee to start managing your team.',
              icon: Icons.people_outline,
              action: ElevatedButton.icon(
                onPressed: () => _showAddStaffUnavailable(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Staff'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(employeesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: employees.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final employee = employees[index];
                return _EmployeeCard(employee: employee);
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

    if (!showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            onPressed: () => _showAddStaffUnavailable(context),
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Staff',
          ),
        ],
      ),
      body: body,
    );
  }

  void _showAddStaffUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add staff routing is not available in Phase 2.1 yet.'),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final dynamic employee;

  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            employee.fullName.substring(0, 1).toUpperCase(),
            style: TextStyle(color: colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text(
          employee.fullName,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.badge_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(employee.employeeCode, style: theme.textTheme.bodySmall),
                const SizedBox(width: 12),
                Icon(Icons.work_outline, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(employee.position, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: employee.isActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                employee.isActive ? 'Active' : 'Inactive',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: employee.isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        trailing: Consumer(
          builder: (context, ref, child) {
            return IconButton(
              onPressed: () => _confirmDeactivation(context, ref),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Deactivate Staff',
            );
          },
        ),
      ),
    );
  }

  void _confirmDeactivation(BuildContext context, WidgetRef ref) {
    ModernAlert.show(
      context,
      title: 'Deactivate Staff',
      message: 'Are you sure you want to deactivate ${employee.fullName}? They will no longer be able to log in.',
      confirmLabel: 'Deactivate',
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.red,
      onConfirm: () async {
        await ref.read(staffNotifierProvider.notifier).deactivateEmployee(employee.id);
        ref.refresh(employeesProvider);
      },
    );
  }
}
