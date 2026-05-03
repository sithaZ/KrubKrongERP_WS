import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// App navigation shell with bottom navigation bar
class AppNavigationShell extends ConsumerWidget {

  const AppNavigationShell({
    super.key,
    required this.navigationShell,
  });
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isPrivileged = (user?.isOwner ?? false) || (user?.isAdmin ?? false);

    // Map of destination index to branch index
    // Branches: 0: Dashboard, 1: POS, 2: Orders, 3: Products, 4: Staff, 5: Attendance, 6: Profile
    final List<int> branchMap = [];
    
    if (isPrivileged) {
      branchMap.addAll([0, 1, 2, 3, 4, 5, 6]); // Owner: Dash, POS, Ord, Prod, Staff, Att, Prof
    } else {
      branchMap.addAll([1, 3, 5, 6]); // Staff: POS, Products, Attendance, Profile
    }

    // Find current destination index based on current branch
    final currentDestinationIndex = branchMap.indexOf(navigationShell.currentIndex);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentDestinationIndex != -1 ? currentDestinationIndex : 0,
        onDestinationSelected: (index) {
          navigationShell.goBranch(branchMap[index]);
        },
        destinations: [
          if (isPrivileged)
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
          const NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'POS',
          ),
          if (isPrivileged)
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          if (isPrivileged)
            const NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Staff',
            ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Attendance',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
