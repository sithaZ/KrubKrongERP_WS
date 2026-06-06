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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black54 : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isDark ? Colors.white70 : Colors.black54,
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
