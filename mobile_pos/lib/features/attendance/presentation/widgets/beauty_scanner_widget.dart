import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:crypto/crypto.dart';
import '../../../../core/core.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/errors/failures.dart';
import '../providers/attendance_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/common_widgets.dart';

class BeautyScannerWidget extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final Function(String)? onScanSuccess;

  const BeautyScannerWidget({
    super.key,
    required this.onClose,
    this.onScanSuccess,
  });

  @override
  ConsumerState<BeautyScannerWidget> createState() => _BeautyScannerWidgetState();
}

class _BeautyScannerWidgetState extends ConsumerState<BeautyScannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late MobileScannerController _scannerController;
  bool _isLoading = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String code) async {
    if (_isLoading || _hasScanned) return;

    setState(() {
      _isLoading = true;
      _hasScanned = true;
    });

    try {
      final service = ref.read(attendanceServiceProvider);
      final authState = ref.read(authProvider);

      // 1. Get GPS coordinates
      final position = await service.getCurrentPosition();

      // 2. Perform backend check-in
      await service.checkIn(
        employeeId: authState.user!.id,
        lat: position.latitude,
        lng: position.longitude,
        qrToken: code,
      );

      // 3. Refresh attendance records
      ref.invalidate(employeeAttendanceHistoryProvider(authState.user!.id));
      ref.invalidate(attendanceRecordsProvider);

      if (widget.onScanSuccess != null) {
        widget.onScanSuccess!(code);
      } else {
        if (mounted) {
          ModernAlert.show(
            context,
            title: context.tr('Success!'),
            message: context.tr('You have clocked in successfully.'),
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
          );
        }
        widget.onClose();
      }
    } catch (e) {
      // Re-enable scanning on failure
      setState(() {
        _isLoading = false;
        _hasScanned = false;
      });

      final displayMessage = e is Failure ? e.message : e.toString();
      if (mounted) {
        ModernAlert.show(
          context,
          title: context.tr('Check-in Failed'),
          message: displayMessage,
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanAreaSize = 250.0;

    return Stack(
      children: [
        // Camera View
        Positioned.fill(
          child: MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
        ),

        // Semi-transparent overlay with scanning frame hole (Custom Paint mask)
        Positioned.fill(
          child: CustomPaint(
            painter: ScannerMaskPainter(scanAreaSize: scanAreaSize),
          ),
        ),

        // Custom Neon Corner brackets & scan animation
        Center(
          child: SizedBox(
            width: scanAreaSize,
            height: scanAreaSize,
            child: Stack(
              children: [
                // Corner Brackets
                CustomPaint(
                  size: Size(scanAreaSize, scanAreaSize),
                  painter: ScannerFramePainter(),
                ),

                // Animated vertical laser line
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final topOffset = _animationController.value * (scanAreaSize - 4);
                    return Positioned(
                      top: topOffset,
                      left: 6,
                      right: 6,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Instructions and title
        Positioned(
          bottom: 80,
          left: 32,
          right: 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('Scan Attendance QR Code'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'Align the shop QR code within the frame to check in automatically',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Close and torch buttons at the top
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close button
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  padding: const EdgeInsets.all(12),
                ),
              ),

              // Torch button
              IconButton(
                onPressed: () => _scannerController.toggleTorch(),
                icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),

        // Loading overlay during API call
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                        SizedBox(height: 16),
                        Text(
                          context.tr('Checking In...'),
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    const radius = 16.0;

    // Top Left Corner
    final path1 = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, radius)
      ..arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius))
      ..lineTo(cornerLength, 0);

    // Top Right Corner
    final path2 = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius))
      ..lineTo(size.width, cornerLength);

    // Bottom Right Corner
    final path3 = Path()
      ..moveTo(size.width, size.height - cornerLength)
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(Offset(size.width - radius, size.height), radius: const Radius.circular(radius))
      ..lineTo(size.width - cornerLength, size.height);

    // Bottom Left Corner
    final path4 = Path()
      ..moveTo(cornerLength, size.height)
      ..lineTo(radius, size.height)
      ..arcToPoint(Offset(0, size.height - radius), radius: const Radius.circular(radius))
      ..lineTo(0, size.height - cornerLength);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScannerMaskPainter extends CustomPainter {
  final double scanAreaSize;

  ScannerMaskPainter({required this.scanAreaSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.65);
    
    // Outer rect path (entire screen)
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Inner rect path (scanning area in the center)
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(center: center, width: scanAreaSize, height: scanAreaSize);
    final innerPath = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
    
    // Combine them to form a hollow path (outer - inner)
    final path = Path.combine(PathOperation.difference, outerPath, innerPath);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ScannerMaskPainter oldDelegate) {
    return oldDelegate.scanAreaSize != scanAreaSize;
  }
}
