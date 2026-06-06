import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../../data/services/attendance_service.dart';
import '../../../staff/domain/entities/employee.dart';
import '../../../staff/presentation/providers/staff_provider.dart';
import '../widgets/beauty_scanner_widget.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isOwnerOrManager = (user?.isOwner ?? false) ||
        (user?.isAdmin ?? false) ||
        (user?.isStrictManager ?? false);

    final body = isOwnerOrManager
        ? const OwnerAttendanceView()
        : const StaffAttendanceView();

    if (!showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: body,
    );
  }
}

class StaffAttendanceView extends ConsumerStatefulWidget {
  const StaffAttendanceView({super.key});

  @override
  ConsumerState<StaffAttendanceView> createState() =>
      _StaffAttendanceViewState();
}

class _StaffAttendanceViewState extends ConsumerState<StaffAttendanceView> {
  bool _isScanning = false;
  bool _isLoading = false;
  bool _selfAttendanceAllowed = false;

  @override
  void initState() {
    super.initState();
    _loadSelfAttendancePermission();
  }

  Future<void> _loadSelfAttendancePermission() async {
    try {
      final service = ref.read(attendanceServiceProvider);
      final settings = await service.getShopSettings();
      final authState = ref.read(authProvider);
      final userRole = authState.user?.rawRole?.toUpperCase() ?? '';

      bool allowed = false;
      if (userRole == 'MANAGER' || userRole == 'OWNER' || userRole == 'ADMIN') {
        allowed = settings['allowManagerSelfAttendance'] == true;
      } else {
        allowed = settings['allowStaffSelfAttendance'] == true;
      }

      if (mounted) {
        setState(() => _selfAttendanceAllowed = allowed);
      }
    } catch (e) {
      debugPrint('Error loading self-attendance permission: $e');
    }
  }

  Future<void> _handleScan(String code) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isScanning = false;
    });

    try {
      final service = ref.read(attendanceServiceProvider);
      final authState = ref.read(authProvider);

      // 1. Get GPS Position (High Accuracy, fetched once)
      final position = await service.getCurrentPosition();

      // 2. Send to backend
      await service.checkIn(
        employeeId: authState.user!.id,
        lat: position.latitude,
        lng: position.longitude,
        qrToken: code,
      );

      // 3. Refresh lists
      ref.invalidate(employeeAttendanceHistoryProvider(authState.user!.id));
      ref.invalidate(attendanceRecordsProvider);

      if (mounted) {
        ModernAlert.show(
          context,
          title: 'Success!',
          message: 'You have clocked in successfully.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      final displayMessage = e is Failure ? e.message : e.toString();
      if (mounted) {
        ModernAlert.show(
          context,
          title: 'Error',
          message: displayMessage,
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSelfCheckIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isScanning = false;
    });

    try {
      final service = ref.read(attendanceServiceProvider);
      final authState = ref.read(authProvider);

      // 1. Get GPS Position
      final position = await service.getCurrentPosition();

      // 2. Send self check-in (no QR token)
      await service.selfCheckIn(
        employeeId: authState.user!.id,
        lat: position.latitude,
        lng: position.longitude,
      );

      // 3. Refresh lists
      ref.invalidate(employeeAttendanceHistoryProvider(authState.user!.id));
      ref.invalidate(attendanceRecordsProvider);

      if (mounted) {
        ModernAlert.show(
          context,
          title: 'Success!',
          message: 'You have self-clocked in successfully.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      final displayMessage = e is Failure ? e.message : e.toString();
      if (mounted) {
        ModernAlert.show(
          context,
          title: 'Error',
          message: displayMessage,
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCheckOut() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isScanning = false;
    });

    try {
      final service = ref.read(attendanceServiceProvider);
      final authState = ref.read(authProvider);
      final position = await service.getCurrentPosition();

      await service.checkOut(
        employeeId: authState.user!.id,
        lat: position.latitude,
        lng: position.longitude,
      );

      ref.invalidate(employeeAttendanceHistoryProvider(authState.user!.id));
      ref.invalidate(attendanceRecordsProvider);

      if (mounted) {
        ModernAlert.show(
          context,
          title: 'Success!',
          message: 'You have clocked out successfully.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      final displayMessage = e is Failure ? e.message : e.toString();
      if (mounted) {
        ModernAlert.show(
          context,
          title: 'Error',
          message: displayMessage,
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLiveShiftStatus(
      Employee employee, ThemeData theme, bool isDark) {
    if (employee.shiftStartTime == null) return const SizedBox.shrink();

    final now = DateTime.now();

    try {
      final parts = employee.shiftStartTime!.split(':');
      if (parts.length == 2) {
        final shiftStartHour = int.parse(parts[0]);
        final shiftStartMin = int.parse(parts[1]);

        final grace = employee.shiftGracePeriodMinutes ?? 15;

        final shiftStart = DateTime(
            now.year, now.month, now.day, shiftStartHour, shiftStartMin);
        final graceLimit = shiftStart.add(Duration(minutes: grace));

        final isLate = now.isAfter(graceLimit);

        return Container(
          margin: const EdgeInsets.only(top: 14, bottom: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your Shift: ${employee.shiftName ?? "Standard"}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${employee.shiftStartTime} - ${employee.shiftEndTime}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Text(
                    'Current Lateness Status:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isLate
                          ? Colors.orange.withOpacity(0.12)
                          : Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isLate ? 'LATE (Check-in now)' : 'ON-TIME',
                      style: TextStyle(
                        color: isLate ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error parsing live shift status: $e');
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final historyAsync =
        ref.watch(employeeAttendanceHistoryProvider(authState.user!.id));
    final employeesAsync = ref.watch(employeesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.qr_code_scanner, size: 60, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Attendance Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              employeesAsync.when(
                data: (employees) {
                  if (employees.isEmpty) return const SizedBox.shrink();
                  final employee = employees.firstWhere(
                    (e) =>
                        e.userId == authState.user?.id ||
                        e.id == authState.user?.id,
                    orElse: () => employees.first,
                  );
                  return _buildLiveShiftStatus(employee, Theme.of(context),
                      Theme.of(context).brightness == Brightness.dark);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  backgroundColor: Colors.black,
                                  body: BeautyScannerWidget(
                                    onClose: () => Navigator.pop(context),
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code_scanner_rounded,
                              size: 18),
                          label: const Text('Scan QR'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleCheckOut,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Check Out'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selfAttendanceAllowed) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleSelfCheckIn,
                        icon: const Icon(Icons.fingerprint_rounded, size: 20),
                        label: const Text('Self Clock In (GPS Only)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.history, size: 20),
              SizedBox(width: 8),
              Text('My Recent Shifts',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: historyAsync.when(
            data: (history) => RefreshIndicator(
              onRefresh: () => ref.refresh(
                  employeeAttendanceHistoryProvider(authState.user!.id).future),
              child: history.isEmpty
                  ? const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: 300,
                        child: Center(child: Text('No shifts recorded yet')),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: history.length,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final record = history[index];
                        final checkIn = DateTime.parse(record['checkIn']);
                        final checkOut = record['checkOut'] != null
                            ? DateTime.parse(record['checkOut'])
                            : null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => context.push(
                                AppRoutePaths.attendanceDetail,
                                extra: record),
                            leading: CircleAvatar(
                              backgroundColor: checkOut == null
                                  ? Colors.green.shade100
                                  : Colors.blue.shade100,
                              child: Icon(
                                checkOut == null ? Icons.login : Icons.logout,
                                color: checkOut == null
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                            ),
                            title:
                                Text(DateFormat('EEEE, MMM d').format(checkIn)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'In: ${DateFormat('hh:mm a').format(checkIn)}' +
                                      (checkOut != null
                                          ? ' - Out: ${DateFormat('hh:mm a').format(checkOut)}'
                                          : ' - Active'),
                                ),
                                if (record['staffId']?['shiftName'] !=
                                    null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Shift: ${record['staffId']['shiftName']} (${record['staffId']['shiftStartTime']} - ${record['staffId']['shiftEndTime']})',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (record['workedHours'] != null)
                                  Text(
                                      '${record['workedHours'].toStringAsFixed(1)}h',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold))
                                else
                                  const Text('...',
                                      style: TextStyle(color: Colors.green)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        (record['attendanceStatus'] == 'LATE' ||
                                                record['status'] == 'late')
                                            ? Colors.orange.withOpacity(0.12)
                                            : Colors.green.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (record['attendanceStatus'] ??
                                            record['status'] ??
                                            'PRESENT')
                                        .toString()
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: (record['attendanceStatus'] ==
                                                  'LATE' ||
                                              record['status'] == 'late')
                                          ? Colors.orange
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class RotatingQrWidget extends StatefulWidget {
  final String secretKey;
  final double size;
  final bool showProgress;
  final bool isStatic;

  const RotatingQrWidget({
    super.key,
    required this.secretKey,
    required this.size,
    this.showProgress = true,
    this.isStatic = false,
  });

  @override
  State<RotatingQrWidget> createState() => _RotatingQrWidgetState();
}

class _RotatingQrWidgetState extends State<RotatingQrWidget> {
  Timer? _timer;
  String _token = '';
  int _secondsRemaining = 300;
  int _generationTimestamp = 0;

  @override
  void initState() {
    super.initState();
    _resetTimer();
    if (!widget.isStatic) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _tick();
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant RotatingQrWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.secretKey != widget.secretKey ||
        oldWidget.isStatic != widget.isStatic) {
      _timer?.cancel();
      _resetTimer();
      if (!widget.isStatic) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _tick();
            });
          }
        });
      }
    }
  }

  void _resetTimer() {
    _generationTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _secondsRemaining = 99999999999;
    _token = _generateTokenString();
  }

  void _tick() {
    if (widget.isStatic) return;
    _secondsRemaining--;
    if (_secondsRemaining <= 0) {
      _resetTimer();
    }
  }

  String _generateTokenString() {
    if (widget.isStatic) {
      return widget.secretKey;
    }
    final input = '${widget.secretKey}:$_generationTimestamp';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    final hash = digest.toString();
    return '$hash|$_generationTimestamp';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: QrImageView(
            data: _token,
            version: QrVersions.auto,
            size: widget.size,
          ),
        ),
        if (widget.showProgress) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  value: _secondsRemaining / 30.0,
                  strokeWidth: 2.5,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Refreshing in ${_secondsRemaining}s',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class OwnerAttendanceView extends ConsumerWidget {
  const OwnerAttendanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(shopSettingsProvider);
    final allRecordsAsync = ref.watch(attendanceRecordsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isManager = user?.isStrictManager ?? false;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return settingsAsync.when(
      data: (settings) {
        final coords = settings['coordinates'];
        final hasLocation =
            coords != null && coords['lat'] != null && coords['lng'] != null;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(shopSettingsProvider);
            ref.invalidate(attendanceRecordsProvider);
            await Future.wait([
              ref.read(shopSettingsProvider.future),
              ref.read(attendanceRecordsProvider.future),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Header/Cards Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isManager) ...[
                        const ManagerClockInOutCard(),
                        const SizedBox(height: 16),
                      ] else ...[
                        // Shop Location & Settings Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurface
                                : AppTheme.lightSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.lightBorder,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.storefront_rounded,
                                        color: AppTheme.primary, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          settings['shopName'] ??
                                              'Shop Profile',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Allowed Radius: ${settings['radius'] ?? 50}m',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: isDark
                                                ? AppTheme.darkTextSecondary
                                                : AppTheme.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(
                                    label: hasLocation
                                        ? 'GPS Pinned'
                                        : 'No GPS Set',
                                    color: hasLocation
                                        ? AppTheme.success
                                        : AppTheme.warning,
                                  ),
                                ],
                              ),
                              if (hasLocation) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.04)
                                        : AppTheme.lightFill,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.redAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Coordinates: ${coords['lat'].toStringAsFixed(5)}, ${coords['lng'].toStringAsFixed(5)}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              Text(
                                'Configure Shop GPS Coordinates',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _setShopLocation(context, ref),
                                      icon: const Icon(
                                          Icons.my_location_rounded,
                                          size: 16),
                                      label: const Text('Pin Current GPS'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _showLinkInputDialog(context, ref),
                                      icon: const Icon(Icons.map_rounded,
                                          size: 16),
                                      label: const Text('Paste Maps Link'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Interactive QR Code Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkSurface
                              : AppTheme.lightSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.darkBorder
                                : AppTheme.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Check-in QR Code',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Have your employees scan this unique shop QR code using their KrubKrong app when they arrive at the shop to check in instantly.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.lightTextSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.security_rounded,
                                            size: 12, color: AppTheme.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Dynamic Code (Anti-Cheat)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _showExpandedQrDialog(
                                context,
                                settings['secretKey'] ?? 'krobkrong_secret_123',
                                settings['shopName'] ?? 'Default Shop',
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Tooltip(
                                  message: 'Tap to enlarge',
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      RotatingQrWidget(
                                        secretKey: settings['secretKey'] ??
                                            'krobkrong_secret_123',
                                        size: 100.0,
                                        showProgress: false,
                                        isStatic: true,
                                      ),
                                      Positioned(
                                        bottom: 2,
                                        right: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.fullscreen_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 2. Divider & Monitor Header Section
              const SliverToBoxAdapter(
                child: Column(
                  children: [
                    Divider(),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.people_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Staff Attendance Monitor',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 3. Monitor List View Section
              allRecordsAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 200,
                        child: Center(
                            child: Text('No attendance records found today')),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final record = records[index];
                          final checkIn = DateTime.parse(record['checkIn']);
                          final checkOut = record['checkOut'] != null
                              ? DateTime.parse(record['checkOut'])
                              : null;
                          final employeeName =
                              record['employeeId']?['fullName'] ?? 'Staff';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () => context.push(
                                  AppRoutePaths.attendanceDetail,
                                  extra: record),
                              leading: CircleAvatar(
                                child: Text(
                                    employeeName.substring(0, 1).toUpperCase()),
                              ),
                              title: Text(employeeName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'In: ${DateFormat('hh:mm a').format(checkIn)}' +
                                        (checkOut != null
                                            ? ' - Out: ${DateFormat('hh:mm a').format(checkOut)}'
                                            : ' - On-Site'),
                                  ),
                                  if (record['staffId']?['shiftName'] !=
                                      null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Shift: ${record['staffId']['shiftName']} (${record['staffId']['shiftStartTime']} - ${record['staffId']['shiftEndTime']})',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(DateFormat('MMM d').format(checkIn),
                                      style: const TextStyle(fontSize: 12)),
                                  if (record['workedHours'] != null)
                                    Text(
                                        '${record['workedHours'].toStringAsFixed(1)}h',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (record['attendanceStatus'] ==
                                                  'LATE' ||
                                              record['status'] == 'late')
                                          ? Colors.orange.withOpacity(0.12)
                                          : Colors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      (record['attendanceStatus'] ??
                                              record['status'] ??
                                              'PRESENT')
                                          .toString()
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: (record['attendanceStatus'] ==
                                                    'LATE' ||
                                                record['status'] == 'late')
                                            ? Colors.orange
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: records.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Future<void> _showLinkInputDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste Google Maps Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share your shop location from the Google Maps app and paste the link here.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://maps.app.goo.gl/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              String input = controller.text.trim();
              if (input.isEmpty) return;

              // Show loading
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );
              }

              double? lat;
              double? lng;

              try {
                // 1. Handle shortened URLs (maps.app.goo.gl)
                if (input.contains('maps.app.goo.gl')) {
                  final dio = ref.read(httpClientInstanceProvider);
                  final response = await dio.get(input,
                      options: Options(
                          followRedirects: true,
                          validateStatus: (status) => status! < 500,
                          headers: {
                            'User-Agent':
                                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
                          }));
                  input = response.realUri.toString();

                  // Fallback: If URL doesn't have coordinates, search the HTML body
                  if (!input.contains('@') && !input.contains('!3d')) {
                    final body = response.data.toString();
                    final bodyMatch =
                        RegExp(r'center=(-?\d+\.\d+)%2C(-?\d+\.\d+)')
                            .firstMatch(body);
                    if (bodyMatch != null) {
                      lat = double.tryParse(bodyMatch.group(1)!);
                      lng = double.tryParse(bodyMatch.group(2)!);
                    }
                  }
                }

                // Debug print the final URL to parse
                debugPrint('Parsing URL: $input');

                // 2. Try to find @lat,lng (Common in browser links)
                final atMatch =
                    RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(input);
                if (atMatch != null) {
                  lat = double.tryParse(atMatch.group(1)!);
                  lng = double.tryParse(atMatch.group(2)!);
                }

                // 3. Try to find q= or query=
                if (lat == null) {
                  final qMatch = RegExp(
                          r'[?&](?:q|query|ll|center)=(-?\d+\.\d+),(-?\d+\.\d+)')
                      .firstMatch(input);
                  if (qMatch != null) {
                    lat = double.tryParse(qMatch.group(1)!);
                    lng = double.tryParse(qMatch.group(2)!);
                  }
                }

                // 4. Try to find !3d lat !4d lng (Common in Place links)
                if (lat == null) {
                  final placeMatch = RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)')
                      .firstMatch(input);
                  if (placeMatch != null) {
                    lat = double.tryParse(placeMatch.group(1)!);
                    lng = double.tryParse(placeMatch.group(2)!);
                  }
                }

                // 5. Try to parse raw "lat, lng"
                if (lat == null) {
                  final rawMatch = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)')
                      .firstMatch(input);
                  if (rawMatch != null) {
                    lat = double.tryParse(rawMatch.group(1)!);
                    lng = double.tryParse(rawMatch.group(2)!);
                  }
                }

                if (context.mounted) Navigator.pop(context); // Close loading

                if (lat != null && lng != null) {
                  final service = ref.read(attendanceServiceProvider);
                  await service.updateShopSettings({
                    'coordinates': {'lat': lat, 'lng': lng},
                  });

                  // Force a hard refresh of the settings
                  ref.invalidate(shopSettingsProvider);
                  await ref.read(shopSettingsProvider.future);

                  if (context.mounted) {
                    Navigator.pop(context); // Close input dialog
                    ModernAlert.show(
                      context,
                      title: 'Location Updated!',
                      message: 'Successfully updated shop to: $lat, $lng',
                      icon: Icons.check_circle_outline,
                      iconColor: Colors.green,
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Could not find coordinates. Try pasting the numbers directly like this: 11.57, 104.85',
                            style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e',
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _setShopLocation(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(attendanceServiceProvider);
      final position = await service.getCurrentPosition();

      await service.updateShopSettings({
        'coordinates': {
          'lat': position.latitude,
          'lng': position.longitude,
        },
      });

      if (context.mounted) {
        ModernAlert.show(
          context,
          title: 'Shop Location Pinned!',
          message:
              'Success! Your shop is now officially pinned at this GPS location. Your staff can now clock in when they are within 50 meters of this spot.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        );
        ref.refresh(shopSettingsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _showExpandedQrDialog(
      BuildContext context, String secretKey, String shopName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss QR',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: ScaleTransition(
                scale:
                    CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shopName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Employee Clock-in Scanner',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.black54),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: RotatingQrWidget(
                          secretKey: secretKey,
                          size: 260.0,
                          showProgress: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Scan QR to Clock In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Place your mobile scanner close to this QR code',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ManagerClockInOutCard extends ConsumerStatefulWidget {
  const ManagerClockInOutCard({super.key});

  @override
  ConsumerState<ManagerClockInOutCard> createState() =>
      _ManagerClockInOutCardState();
}

class _ManagerClockInOutCardState extends ConsumerState<ManagerClockInOutCard> {
  bool _isLoading = false;
  bool _selfAttendanceAllowed = false;

  @override
  void initState() {
    super.initState();
    _loadSelfAttendancePermission();
  }

  Future<void> _loadSelfAttendancePermission() async {
    try {
      final service = ref.read(attendanceServiceProvider);
      final settings = await service.getShopSettings();
      final authState = ref.read(authProvider);
      final userRole = authState.user?.rawRole?.toUpperCase() ?? '';

      bool allowed = false;
      if (userRole == 'MANAGER' || userRole == 'OWNER' || userRole == 'ADMIN') {
        allowed = settings['allowManagerSelfAttendance'] == true;
      } else {
        allowed = settings['allowStaffSelfAttendance'] == true;
      }

      if (mounted) {
        setState(() => _selfAttendanceAllowed = allowed);
      }
    } catch (e) {
      debugPrint('Error loading self-attendance permission: $e');
    }
  }

  Future<void> _handleScan(String code) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(attendanceServiceProvider);
      final authState = ref.read(authProvider);

      final position = await service.getCurrentPosition();

      await service.checkIn(
        employeeId: authState.user!.id,
        lat: position.latitude,
        lng: position.longitude,
        qrToken: code,
      );

      ref.invalidate(employeeAttendanceHistoryProvider(authState.user!.id));
      ref.invalidate(attendanceRecordsProvider);

      if (mounted) {
        ModernAlert.show(
          context,
          title: 'Success!',
          message: 'You have clocked in successfully.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      final displayMessage = e is Failure ? e.message : e.toString();
      if (mounted) {
        ModernAlert.show(
          context,
          title: 'Error',
          message: displayMessage,
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSelfCheckIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(attendanceServiceProvider);
      final authState = ref.read(authProvider);

      final position = await service.getCurrentPosition();

      await service.selfCheckIn(
        employeeId: authState.user!.id,
        lat: position.latitude,
        lng: position.longitude,
      );

      ref.invalidate(employeeAttendanceHistoryProvider(authState.user!.id));
      ref.invalidate(attendanceRecordsProvider);

      if (mounted) {
        ModernAlert.show(
          context,
          title: 'Success!',
          message: 'You have self-clocked in successfully.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      final displayMessage = e is Failure ? e.message : e.toString();
      if (mounted) {
        ModernAlert.show(
          context,
          title: 'Error',
          message: displayMessage,
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCheckOut() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(attendanceServiceProvider);
      final authState = ref.read(authProvider);
      final position = await service.getCurrentPosition();

      await service.checkOut(
        employeeId: authState.user!.id,
        lat: position.latitude,
        lng: position.longitude,
      );

      ref.invalidate(employeeAttendanceHistoryProvider(authState.user!.id));
      ref.invalidate(attendanceRecordsProvider);

      if (mounted) {
        ModernAlert.show(
          context,
          title: 'Success!',
          message: 'You have clocked out successfully.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      final displayMessage = e is Failure ? e.message : e.toString();
      if (mounted) {
        ModernAlert.show(
          context,
          title: 'Error',
          message: displayMessage,
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLiveShiftStatus(
      Employee employee, ThemeData theme, bool isDark) {
    if (employee.shiftStartTime == null) return const SizedBox.shrink();

    final now = DateTime.now();

    try {
      final parts = employee.shiftStartTime!.split(':');
      if (parts.length == 2) {
        final shiftStartHour = int.parse(parts[0]);
        final shiftStartMin = int.parse(parts[1]);

        final grace = employee.shiftGracePeriodMinutes ?? 15;

        final shiftStart = DateTime(
            now.year, now.month, now.day, shiftStartHour, shiftStartMin);
        final graceLimit = shiftStart.add(Duration(minutes: grace));

        final isLate = now.isAfter(graceLimit);

        return Container(
          margin: const EdgeInsets.only(top: 14, bottom: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your Shift: ${employee.shiftName ?? "Standard"}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${employee.shiftStartTime} - ${employee.shiftEndTime}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Text(
                    'Current Lateness Status:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isLate
                          ? Colors.orange.withOpacity(0.12)
                          : Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isLate ? 'LATE (Check-in now)' : 'ON-TIME',
                      style: TextStyle(
                        color: isLate ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error parsing live shift status: $e');
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Attendance Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Clock-in or out for your shift',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          employeesAsync.when(
            data: (employees) {
              if (employees.isEmpty) return const SizedBox.shrink();
              final employee = employees.firstWhere(
                (e) =>
                    e.userId == authState.user?.id ||
                    e.id == authState.user?.id,
                orElse: () => employees.first,
              );
              return _buildLiveShiftStatus(employee, theme, isDark);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            backgroundColor: Colors.black,
                            body: BeautyScannerWidget(
                              onClose: () => Navigator.pop(context),
                              onScanSuccess: (code) {
                                // Handled automatically, but we define callback to ensure pop behavior
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text('Scan QR'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleCheckOut,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Check Out'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (_selfAttendanceAllowed && !_isLoading) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleSelfCheckIn,
                icon: const Icon(Icons.fingerprint_rounded, size: 20),
                label: const Text('Self Clock In (GPS Only)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
