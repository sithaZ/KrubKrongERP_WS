import 'package:flutter/material.dart';
import 'beauty_scanner_widget.dart';
import '../../../../core/theme/app_theme.dart';

class GlobalScannerWrapper extends StatefulWidget {
  final Widget child;

  const GlobalScannerWrapper({
    super.key,
    required this.child,
  });

  @override
  State<GlobalScannerWrapper> createState() => _GlobalScannerWrapperState();
}

class _GlobalScannerWrapperState extends State<GlobalScannerWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _openScanner() {
    if (_isOpen) return;
    setState(() {
      _isOpen = true;
    });
    _slideController.forward();
  }

  void _closeScanner() {
    if (!_isOpen) return;
    _slideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isOpen = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Main App Content wrapped with a gesture detector on the top area
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                child: widget.child,
              ),
            ],
          ),
        ),

        // Small Pull Down handle floating at the top center
        if (!_isOpen)
          Positioned(
            top: MediaQuery.of(context).padding.top + 2,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 5) {
                    _openScanner();
                  }
                },
                onTap: _openScanner,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black87 : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pull to Scan',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Sliding Scanner overlay sheet
        if (_isOpen)
          SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.black,
              child: BeautyScannerWidget(
                onClose: _closeScanner,
              ),
            ),
          ),
      ],
    );
  }
}
