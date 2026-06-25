import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';
import '../../features/dashboard/presentation/pages/dashboard_screen_synced.dart';
import '../../features/pos/presentation/pages/pos_screen.dart';
import '../../features/operations/presentation/pages/operations_hub_screen.dart';
import '../../features/more/presentation/pages/more_hub_screen.dart';

import '../../features/attendance/presentation/widgets/global_scanner_wrapper.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class ManagerShellScreen extends ConsumerStatefulWidget {
  const ManagerShellScreen({super.key});

  @override
  ConsumerState<ManagerShellScreen> createState() => _ManagerShellScreenState();
}

class _ManagerShellScreenState extends ConsumerState<ManagerShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      const DashboardScreen(),
      const PosScreen(),
      const OperationsHubScreen(),
      const MoreHubScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isOwnerOrAdmin = user?.isOwnerOrAdmin ?? false;

    final scaffoldContent = Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: l10n.dashboard,
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: l10n.pos,
            ),
            NavigationDestination(
              icon: Icon(Icons.business_center_outlined),
              selectedIcon: Icon(Icons.business_center_rounded),
              label: context.tr('Operations'),
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_rounded),
              selectedIcon: Icon(Icons.more_horiz_rounded),
              label: l10n.more,
            ),
          ],
        ),
      ),
    );

    if (isOwnerOrAdmin) {
      return scaffoldContent;
    }

    return GlobalScannerWrapper(
      child: scaffoldContent,
    );
  }
}
