import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class ManagerShellScreen extends ConsumerWidget {
  const ManagerShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager App Shell'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Welcome, ${user?.displayName ?? 'Manager'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Phase 2.1 is active. This manager shell is ready for employee, attendance, and payroll modules to plug in next.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _PlaceholderCard(
            title: 'Session Summary',
            lines: [
              'Role: ${user?.roleLabel ?? 'UNKNOWN'}',
              'Company ID: ${user?.companyId ?? 'Not available'}',
              'Email: ${user?.email ?? 'Not available'}',
            ],
          ),
          const SizedBox(height: 16),
          const _PlaceholderCard(
            title: 'Planned Manager Modules',
            lines: [
              'Employees',
              'Attendance Overview',
              'Payroll',
              'Settings',
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(line),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
