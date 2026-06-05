import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../app/router/route_paths.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class OperationsHubScreen extends ConsumerWidget {
  const OperationsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    // RBAC: Check permissions
    final isOwner = user?.rawRole.toUpperCase() == 'OWNER' || user?.rawRole.toUpperCase() == 'ADMIN';
    final isManager = user?.rawRole.toUpperCase() == 'MANAGER';

    // Build items list based on role
    final List<_HubItem> items = [
      _HubItem(
        icon: Icons.inventory_2_outlined,
        title: 'Inventory',
        description: 'Track stock counts and receive low stock alerts.',
        route: AppRoutePaths.inventory,
        color: AppTheme.primary,
        bgColor: AppTheme.primaryContainer,
      ),
      _HubItem(
        icon: Icons.shopping_bag_outlined,
        title: 'Products',
        description: 'Manage items, pricing, and category catalog.',
        route: AppRoutePaths.products,
        color: AppTheme.info,
        bgColor: AppTheme.infoSurface,
      ),
      if (isOwner) ...[
        _HubItem(
          icon: Icons.local_shipping_outlined,
          title: 'Suppliers',
          description: 'Directory of suppliers and vendor records.',
          route: AppRoutePaths.suppliers,
          color: AppTheme.warning,
          bgColor: AppTheme.warningSurface,
        ),
        _HubItem(
          icon: Icons.shopping_cart_checkout_outlined,
          title: 'Purchase Orders',
          description: 'Raise, monitor, and receive restocking orders.',
          route: AppRoutePaths.purchaseOrders,
          color: Colors.purple,
          bgColor: Colors.purple.withOpacity(0.08),
        ),
      ],
      _HubItem(
        icon: Icons.analytics_outlined,
        title: 'Reports',
        description: 'View sales trends, revenue summary, and analytics.',
        route: AppRoutePaths.reports,
        color: AppTheme.success,
        bgColor: AppTheme.successSurface,
      ),
      _HubItem(
        icon: Icons.receipt_long_outlined,
        title: 'Orders',
        description: 'View sales orders and transaction history.',
        route: AppRoutePaths.orders,
        color: Colors.indigo,
        bgColor: Colors.indigo.withOpacity(0.08),
      ),
      if (isOwner)
        _HubItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Expenses',
          description: 'Log and track operating costs and cash outflows.',
          route: AppRoutePaths.expenses,
          color: AppTheme.error,
          bgColor: AppTheme.errorSurface,
        ),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Operations'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
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
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Operations Hub',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ERP Business Tools',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage items, track stock, review vendor directories, and analyze financial reports.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Options Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _GridHubCard(item: item, isDark: isDark);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HubItem {
  const _HubItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final String route;
  final Color color;
  final Color bgColor;
}

class _GridHubCard extends StatelessWidget {
  const _GridHubCard({required this.item, required this.isDark});
  final _HubItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return InkWell(
      onTap: () => context.push(item.route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 19),
            ),
            const Spacer(),
            // Title
            Text(
              item.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            // Description
            Expanded(
              child: Text(
                item.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  fontSize: 10.5,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
