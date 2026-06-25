import 'package:flutter/material.dart';
import '../core.dart';

class ErpPlaceholderScreen extends StatelessWidget {
  const ErpPlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizedTitle = context.tr(title);
    final localizedDescription = context.tr(description);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(localizedTitle),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container with premium gradient shadow
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF1A3BA0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // "Coming Soon" Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.25),
                  ),
                ),
                child: Text(
                  context.tr('COMING SOON'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                localizedTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                localizedDescription,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Action button to go back
              SizedBox(
                width: 180,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(context.tr('Go Back')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
