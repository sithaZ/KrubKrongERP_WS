import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileBottomSheet extends ConsumerWidget {
  const ProfileBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Profile header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
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
                      style: theme.textTheme.titleLarge?.copyWith(
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
                        user?.name ?? 'User Name',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'No email',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      StatusBadge(
                        label: user?.roleLabel ?? 'ROLE',
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.primaryContainer,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: border),

          // Menu items
          _MenuItem(
            icon: Icons.person_outline_rounded,
            label: 'Edit Profile',
            isDark: isDark,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.language_rounded,
            label: 'Language',
            trailing: Text(
              'English',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            isDark: isDark,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.storefront_rounded,
            label: 'Switch Shop',
            isDark: isDark,
            onTap: () {},
          ),

          Divider(height: 1, color: border),

          // Logout
          _MenuItem(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            color: AppTheme.error,
            isDark: isDark,
            onTap: () {
              final authNotifier = ref.read(authProvider.notifier);
              Navigator.pop(context);
              _showLogoutDialog(context, () => authNotifier.logout());
            },
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, VoidCallback onConfirmLogout) {
    ModernAlert.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of your account?',
      icon: Icons.logout_rounded,
      iconColor: AppTheme.error,
      confirmLabel: 'Sign Out',
      cancelLabel: 'Cancel',
      onConfirm: onConfirmLogout,
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.trailing,
    this.color,
  });
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: color ?? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary), size: 20),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: resolvedColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? (color == null ? const Icon(Icons.chevron_right_rounded, size: 18) : null),
    );
  }
}
