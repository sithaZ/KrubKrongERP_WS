import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../../data/services/attendance_service.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isOwner = (user?.isOwner ?? false) || (user?.isAdmin ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: isOwner ? const OwnerAttendanceView() : const StaffAttendanceView(),
    );
  }
}

class StaffAttendanceView extends ConsumerStatefulWidget {
  const StaffAttendanceView({super.key});

  @override
  ConsumerState<StaffAttendanceView> createState() => _StaffAttendanceViewState();
}

class _StaffAttendanceViewState extends ConsumerState<StaffAttendanceView> {
  bool _isScanning = false;
  bool _isLoading = false;

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
      if (mounted) {
        ModernAlert.show(
          context,
          title: 'Error',
          message: e.toString(),
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final historyAsync = ref.watch(employeeAttendanceHistoryProvider(authState.user!.id));

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
                'Scan to Clock In',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_isScanning)
                SizedBox(
                  height: 250,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: MobileScanner(
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
                )
              else
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isScanning = true),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Open Scanner'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
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
              Text('My Recent Shifts', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: historyAsync.when(
            data: (history) => RefreshIndicator(
              onRefresh: () => ref.refresh(employeeAttendanceHistoryProvider(authState.user!.id).future),
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
                        final checkOut = record['checkOut'] != null ? DateTime.parse(record['checkOut']) : null;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: checkOut == null ? Colors.green.shade100 : Colors.blue.shade100,
                              child: Icon(
                                checkOut == null ? Icons.login : Icons.logout,
                                color: checkOut == null ? Colors.green : Colors.blue,
                              ),
                            ),
                            title: Text(DateFormat('EEEE, MMM d').format(checkIn)),
                            subtitle: Text(
                              'In: ${DateFormat('hh:mm a').format(checkIn)}' +
                              (checkOut != null ? ' - Out: ${DateFormat('hh:mm a').format(checkOut)}' : ' - Active'),
                            ),
                            trailing: record['workedHours'] != null
                                ? Text('${record['workedHours'].toStringAsFixed(1)}h', 
                                    style: const TextStyle(fontWeight: FontWeight.bold))
                                : const Text('...', style: TextStyle(color: Colors.green)),
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

class OwnerAttendanceView extends ConsumerWidget {
  const OwnerAttendanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(shopSettingsProvider);
    final allRecordsAsync = ref.watch(attendanceRecordsProvider);

    return settingsAsync.when(
      data: (settings) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildShopStatusCard(context, settings),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Shop QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          QrImageView(
                            data: settings['secretKey'],
                            version: QrVersions.auto,
                            size: 140.0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _setShopLocation(context, ref),
                        icon: const Icon(Icons.my_location),
                        label: const Text('My GPS'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showLinkInputDialog(context, ref),
                        icon: const Icon(Icons.link),
                        label: const Text('Paste Link'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.people, size: 20),
                SizedBox(width: 8),
                Text('Staff Attendance Monitor', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: allRecordsAsync.when(
              data: (records) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(attendanceRecordsProvider);
                  await ref.read(attendanceRecordsProvider.future);
                },
                child: records.isEmpty
                    ? const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 300,
                          child: Center(child: Text('No attendance records found')),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: records.length,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final checkIn = DateTime.parse(record['checkIn']);
                          final checkOut = record['checkOut'] != null ? DateTime.parse(record['checkOut']) : null;
                          final employeeName = record['employeeId']?['fullName'] ?? 'Staff';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(employeeName.substring(0, 1).toUpperCase()),
                              ),
                              title: Text(employeeName),
                              subtitle: Text(
                                'In: ${DateFormat('hh:mm a').format(checkIn)}' +
                                (checkOut != null ? ' - Out: ${DateFormat('hh:mm a').format(checkOut)}' : ' - On-Site'),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(DateFormat('MMM d').format(checkIn), style: const TextStyle(fontSize: 12)),
                                  if (record['workedHours'] != null)
                                    Text('${record['workedHours'].toStringAsFixed(1)}h', 
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildShopStatusCard(BuildContext context, Map<String, dynamic> settings) {
    final coords = settings['coordinates'];
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.store, size: 40, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(settings['shopName'] ?? 'My Shop', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Radius: ${settings['radius']}m', style: const TextStyle(color: Colors.grey)),
                  if (coords != null)
                    Text('Location: ${coords['lat'].toStringAsFixed(4)}, ${coords['lng'].toStringAsFixed(4)}', 
                        style: const TextStyle(fontSize: 12, color: Colors.blue)),
                ],
              ),
            ),
          ],
        ),
      ),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              String input = controller.text.trim();
              if (input.isEmpty) return;

              // Show loading
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
              }

              double? lat;
              double? lng;

              try {
                // 1. Handle shortened URLs (maps.app.goo.gl)
                if (input.contains('maps.app.goo.gl')) {
                  final dio = ref.read(httpClientInstanceProvider);
                  final response = await dio.get(
                    input, 
                    options: Options(
                      followRedirects: true, 
                      validateStatus: (status) => status! < 500,
                      headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
                    )
                  );
                  input = response.realUri.toString();
                  
                  // Fallback: If URL doesn't have coordinates, search the HTML body
                  if (!input.contains('@') && !input.contains('!3d')) {
                    final body = response.data.toString();
                    final bodyMatch = RegExp(r'center=(-?\d+\.\d+)%2C(-?\d+\.\d+)').firstMatch(body);
                    if (bodyMatch != null) {
                      lat = double.tryParse(bodyMatch.group(1)!);
                      lng = double.tryParse(bodyMatch.group(2)!);
                    }
                  }
                }

                // Debug print the final URL to parse
                debugPrint('Parsing URL: $input');

                // 2. Try to find @lat,lng (Common in browser links)
                final atMatch = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(input);
                if (atMatch != null) {
                  lat = double.tryParse(atMatch.group(1)!);
                  lng = double.tryParse(atMatch.group(2)!);
                }

                // 3. Try to find q= or query=
                if (lat == null) {
                  final qMatch = RegExp(r'[?&](?:q|query|ll|center)=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(input);
                  if (qMatch != null) {
                    lat = double.tryParse(qMatch.group(1)!);
                    lng = double.tryParse(qMatch.group(2)!);
                  }
                }

                // 4. Try to find !3d lat !4d lng (Common in Place links)
                if (lat == null) {
                  final placeMatch = RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)').firstMatch(input);
                  if (placeMatch != null) {
                    lat = double.tryParse(placeMatch.group(1)!);
                    lng = double.tryParse(placeMatch.group(2)!);
                  }
                }

                // 5. Try to parse raw "lat, lng"
                if (lat == null) {
                  final rawMatch = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)').firstMatch(input);
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
                        content: Text('Could not find coordinates. Try pasting the numbers directly like this: 11.57, 104.85', style: TextStyle(color: Colors.white)),
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
                      content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
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
          message: 'Success! Your shop is now officially pinned at this GPS location. Your staff can now clock in when they are within 50 meters of this spot.',
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
}
