import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/core.dart';

/// App navigation shell with bottom navigation bar
class AppNavigationShell extends ConsumerWidget {
  const AppNavigationShell({
    super.key,
    required this.navigationShell,
  });
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isPrivileged = (user?.isOwner ?? false) || (user?.isAdmin ?? false);
    final l10n = context.l10n;

    final List<int> branchMap = [];
    if (isPrivileged) {
      branchMap.addAll([0, 1, 2, 3, 4, 5, 6]);
    } else {
      branchMap.addAll([1, 3, 5, 6]);
    }

    final currentDestinationIndex = branchMap.indexOf(navigationShell.currentIndex);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
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
          selectedIndex: currentDestinationIndex != -1 ? currentDestinationIndex : 0,
          onDestinationSelected: (index) {
            navigationShell.goBranch(branchMap[index]);
          },
          destinations: [
            if (isPrivileged)
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: l10n.dashboard,
              ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: l10n.pos,
            ),
            if (isPrivileged)
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: l10n.orders,
              ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: l10n.products,
            ),
            if (isPrivileged)
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: l10n.staff,
              ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon: Icon(Icons.qr_code_scanner_rounded),
              label: l10n.attendance,
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}
