import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context, ref),
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile Hero Section ─────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, Color(0xFF1A3BA0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user?.initials ?? 'U',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? l10n.userNameFallback,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
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

            // ── Info Items ───────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Account Information'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Info card group
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: context.tr('Email'),
                          value: user?.email ?? context.tr('N/A'),
                          isDark: isDark,
                          showDivider: true,
                        ),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: context.tr('Phone'),
                          value: user?.phone ?? context.tr('N/A'),
                          isDark: isDark,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Danger Zone
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context, ref),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(l10n.signOut),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                        foregroundColor: colorScheme.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    ModernAlert.show(
      context,
      title: context.l10n.signOutTitle,
      message: context.l10n.signOutMessage,
      icon: Icons.logout_rounded,
      iconColor: AppTheme.error,
      confirmLabel: context.l10n.signOut,
      cancelLabel: context.l10n.cancel,
      onConfirm: () => ref.read(authProvider.notifier).logout(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.showDivider,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: AppTheme.primary),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 66,
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
      ],
    );
  }
}
