import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/attendance/presentation/pages/attendance_screen.dart';

class EmployeeShellScreen extends ConsumerStatefulWidget {
  const EmployeeShellScreen({super.key});

  @override
  ConsumerState<EmployeeShellScreen> createState() => _EmployeeShellScreenState();
}

class _EmployeeShellScreenState extends ConsumerState<EmployeeShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final user = ref.watch(currentUserProvider);
    final pages = [
      _EmployeeHomeView(userName: user?.displayName, userRole: user?.roleLabel, companyId: user?.companyId, email: user?.email),
      const AttendanceScreen(showAppBar: false),
    ];
    final titles = ['Employee App Shell', 'My Attendance'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Attendance',
          ),
        ],
      ),
    );
  }
}

class _EmployeeHomeView extends StatelessWidget {
  const _EmployeeHomeView({
    required this.userName,
    required this.userRole,
    required this.companyId,
    required this.email,
  });

  final String? userName;
  final String? userRole;
  final String? companyId;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Welcome, ${userName ?? 'Employee'}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Phase 2.1 is active. Your employee shell now includes self-service attendance using the existing attendance feature.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _PlaceholderCard(
          title: 'Session Summary',
          lines: [
            'Role: ${userRole ?? 'UNKNOWN'}',
            'Company ID: ${companyId ?? 'Not available'}',
            'Email: ${email ?? 'Not available'}',
          ],
        ),
        const SizedBox(height: 16),
        const _PlaceholderCard(
          title: 'Employee Modules',
          lines: [
            'Attendance check-in',
            'Attendance check-out',
            'My Attendance history',
            'My Payroll',
          ],
        ),
      ],
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
