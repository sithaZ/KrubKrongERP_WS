import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/core.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../../data/services/attendance_service.dart';

class AttendanceDetailScreen extends ConsumerStatefulWidget {
  const AttendanceDetailScreen({
    super.key,
    required this.record,
  });

  final Map<String, dynamic> record;

  @override
  ConsumerState<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends ConsumerState<AttendanceDetailScreen> {
  late Map<String, dynamic> _currentRecord;
  bool _isLoading = false;

  String _statusLabel(BuildContext context, String? status) {
    switch (status?.toUpperCase()) {
      case 'PRESENT':
        return context.tr('Present');
      case 'ABSENT':
        return context.tr('Absent');
      case 'LATE':
        return context.tr('Late');
      case 'HALF_DAY':
        return context.tr('Half Day');
      case 'LEAVE':
        return context.tr('Leave');
      case 'HOLIDAY':
        return context.tr('Holiday');
      default:
        return status ?? '--';
    }
  }

  String _sourceLabel(BuildContext context, String? source) {
    switch (source?.toLowerCase()) {
      case 'qr':
        return context.tr('QR');
      case 'mobile':
        return context.tr('Mobile');
      case 'manual':
        return context.tr('Manual');
      default:
        return context.tr('Unknown');
    }
  }

  @override
  void initState() {
    super.initState();
    _currentRecord = Map<String, dynamic>.from(widget.record);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PRESENT':
        return Colors.green;
      case 'LATE':
        return Colors.orange;
      case 'HALF_DAY':
        return Colors.amber;
      case 'ABSENT':
        return Colors.red;
      case 'LEAVE':
        return Colors.purple;
      case 'HOLIDAY':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getSourceIcon(String? source) {
    switch (source?.toLowerCase()) {
      case 'qr':
        return Icons.qr_code_scanner;
      case 'mobile':
        return Icons.phone_android;
      case 'manual':
        return Icons.edit_note;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '--:--';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatFullDate(String? dateStr) {
    if (dateStr == null) return '--';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _showCorrectionDialog() async {
    final service = ref.read(attendanceServiceProvider);
    final authState = ref.read(authProvider);

    String selectedStatus = _currentRecord['attendanceStatus'] ?? 'PRESENT';
    final noteController = TextEditingController(text: _currentRecord['note'] ?? '');
    
    DateTime? checkInDateTime;
    DateTime? checkOutDateTime;

    if (_currentRecord['checkInTime'] != null) {
      checkInDateTime = DateTime.parse(_currentRecord['checkInTime']);
    } else if (_currentRecord['checkIn'] != null) {
      checkInDateTime = DateTime.parse(_currentRecord['checkIn']);
    }

    if (_currentRecord['checkOutTime'] != null) {
      checkOutDateTime = DateTime.parse(_currentRecord['checkOutTime']);
    } else if (_currentRecord['checkOut'] != null) {
      checkOutDateTime = DateTime.parse(_currentRecord['checkOut']);
    }

    final checkInTimeController = TextEditingController(
      text: checkInDateTime != null ? DateFormat('HH:mm').format(checkInDateTime) : '',
    );
    final checkOutTimeController = TextEditingController(
      text: checkOutDateTime != null ? DateFormat('HH:mm').format(checkOutDateTime) : '',
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit_calendar, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(context.tr('Manual Correction')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr(
                        'Correct timestamps or status below. Doing so will flag this log as "Manual" and record your user audit trail.',
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: context.tr('Attendance Status'),
                        border: OutlineInputBorder(),
                      ),
                      items: ['PRESENT', 'ABSENT', 'LATE', 'HALF_DAY', 'LEAVE', 'HOLIDAY']
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(_statusLabel(context, role)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: checkInTimeController,
                      decoration: InputDecoration(
                        labelText: context.tr('Check-In Time (HH:mm)'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.login),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: checkOutTimeController,
                      decoration: InputDecoration(
                        labelText: context.tr('Check-Out Time (HH:mm)'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.logout),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: context.tr('Reason / Note'),
                        border: OutlineInputBorder(),
                        hintText: context.tr('Enter reason for this correction'),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('Cancel')),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setDialogState(() => _isLoading = true);
                          try {
                            final baseDateStr = _currentRecord['attendanceDate'] ?? 
                                _currentRecord['workDate'] ?? 
                                DateFormat('yyyy-MM-dd').format(DateTime.now());

                            final payload = <String, dynamic>{
                              'attendanceStatus': selectedStatus,
                              'note': noteController.text.trim(),
                            };

                            if (checkInTimeController.text.isNotEmpty) {
                              payload['checkInTime'] = '${baseDateStr}T${checkInTimeController.text}:00.000Z';
                              payload['checkIn'] = payload['checkInTime'];
                            }

                            if (checkOutTimeController.text.isNotEmpty) {
                              payload['checkOutTime'] = '${baseDateStr}T${checkOutTimeController.text}:00.000Z';
                              payload['checkOut'] = payload['checkOutTime'];
                            }

                            await service.updateAttendance(_currentRecord['_id'], payload);

                            // Force refresh listings
                            ref.invalidate(attendanceRecordsProvider);
                            if (_currentRecord['staffId']?['_id'] != null) {
                              ref.invalidate(employeeAttendanceHistoryProvider(_currentRecord['staffId']['_id']));
                            }

                            if (mounted) {
                              Navigator.pop(context); // Close dialog
                              ModernAlert.show(
                                context,
                                title: context.tr('Correction Applied!'),
                                message: context.tr(
                                  'Attendance record updated and audit trail saved.',
                                ),
                                icon: Icons.check_circle_outline,
                                iconColor: Colors.green,
                              );
                              // Pop back
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            final displayMessage = e is Failure ? e.message : e.toString();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${context.tr('Error')}: $displayMessage',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setDialogState(() => _isLoading = false);
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(context.tr('Save Correction')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isOwnerOrAdmin = user?.isOwnerOrAdmin ?? false;

    final staff = _currentRecord['staffId'] ?? _currentRecord['employeeId'];
    final employeeName = staff?['fullName'] ?? context.tr('Staff Member');
    final department = staff?['department'] ?? context.tr('Operations');
    final roleName = staff?['role'] ?? context.tr('Employee');
    final employeeCode = staff?['employeeCode'] ?? context.tr('EMP-N/A');

    final checkInVal = _currentRecord['checkInTime'] ?? _currentRecord['checkIn'];
    final checkOutVal = _currentRecord['checkOutTime'] ?? _currentRecord['checkOut'];

    final workHours = double.tryParse((_currentRecord['workHours'] ?? _currentRecord['workedHours'] ?? 0.0).toString()) ?? 0.0;
    final overtime = double.tryParse((_currentRecord['overtimeHours'] ?? 0.0).toString()) ?? 0.0;
    final lateMins = int.tryParse((_currentRecord['lateMinutes'] ?? 0).toString()) ?? 0;
    final earlyLeave = int.tryParse((_currentRecord['earlyLeaveMinutes'] ?? 0).toString()) ?? 0;

    final hasCheckIn = checkInVal != null;
    final hasCheckOut = checkOutVal != null;

    final inLocation = _currentRecord['checkInLocation'];
    final outLocation = _currentRecord['checkOutLocation'];
    final locStatus = _currentRecord['locationStatus'] ?? 'unknown';

    final source = _currentRecord['source'] ?? 'qr';
    final corrections = _currentRecord['correctionHistory'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Attendance Detail')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Employee Profile Header Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        employeeName.substring(0, 1).toUpperCase(),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employeeName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$roleName • $department',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${context.tr('ID')}: $employeeCode',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_currentRecord['attendanceStatus']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusLabel(context, _currentRecord['attendanceStatus'] ?? 'PRESENT'),
                        style: TextStyle(
                          color: _getStatusColor(_currentRecord['attendanceStatus']),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (staff != null && staff['shiftName'] != null) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                color: Colors.blue.shade50.withOpacity(0.15),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${context.tr('Shift')}: ${staff['shiftName']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${context.tr('Schedule')}: ${staff['shiftStartTime']} - ${staff['shiftEndTime']} (${context.tr('Grace Period')}: ${staff['shiftGracePeriodMinutes'] ?? 15} ${context.tr('mins')})',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 2. Summary Status & Spacing Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: context.tr('Worked'),
                    value: '${workHours.toStringAsFixed(1)}h',
                    icon: Icons.timer_outlined,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: context.tr('Overtime'),
                    value: '${overtime.toStringAsFixed(1)}h',
                    icon: Icons.add_circle_outline,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: context.tr('Late'),
                    value: '${lateMins}m',
                    icon: Icons.alarm_on,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: context.tr('Early Leave'),
                    value: '${earlyLeave}m',
                    icon: Icons.exit_to_app,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Shift Timeline & Tracking Sources
            Text(
              context.tr('Timeline & Tracking Details'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTimelineRow(
                      context: context,
                      title: context.tr('Check-In'),
                      time: _formatDateTime(checkInVal),
                      date: _formatFullDate(checkInVal),
                      location: inLocation != null 
                          ? '${inLocation['lat'].toStringAsFixed(4)}, ${inLocation['lng'].toStringAsFixed(4)}' 
                          : context.tr('No location registered'),
                      source: source,
                      status: hasCheckIn ? context.tr('Completed') : context.tr('Missing'),
                      icon: Icons.login,
                      iconColor: Colors.green,
                    ),
                    const Divider(height: 32),
                    _buildTimelineRow(
                      context: context,
                      title: context.tr('Check-Out'),
                      time: _formatDateTime(checkOutVal),
                      date: _formatFullDate(checkOutVal),
                      location: outLocation != null 
                          ? '${outLocation['lat'].toStringAsFixed(4)}, ${outLocation['lng'].toStringAsFixed(4)}' 
                          : context.tr('No location registered'),
                      source: source,
                      status: hasCheckOut ? context.tr('Completed') : context.tr('Missing'),
                      icon: Icons.logout,
                      iconColor: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. GPS & Geofence Details
            Text(
              context.tr('Geofencing Validation'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          locStatus == 'on_site' ? Icons.check_circle : Icons.warning_amber_rounded,
                          color: locStatus == 'on_site' ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          locStatus == 'on_site'
                              ? context.tr('Check-In verified on site')
                              : context.tr('Check-In completed remotely'),
                          style: TextStyle(fontWeight: FontWeight.bold, color: locStatus == 'on_site' ? Colors.green.shade900 : Colors.orange.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        'KrubKrong ERP enforces geographic validation for employees clocking in to ensure they are on premises.',
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Notes Card
            if (_currentRecord['note'] != null && _currentRecord['note'].toString().trim().isNotEmpty) ...[
              Text(
                context.tr('Notes'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _currentRecord['note'],
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 6. Correction History Audit Trail Log
            Text(
              context.tr('Correction History & Audit Trail'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (corrections.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    context.tr(
                      'No manual corrections have been recorded for this log. The record matches initial device timestamps.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              Column(
                children: corrections.map((corr) {
                  final correctedAt = corr['correctedAt'] != null 
                      ? DateFormat('MMM d, yyyy @ hh:mm a').format(DateTime.parse(corr['correctedAt']))
                      : context.tr('Unknown');
                  final reason = corr['reason'] ?? context.tr('Manager adjustment');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.orange.shade200),
                    ),
                    color: Colors.orange.shade50.withOpacity(0.3),
                    child: ListTile(
                      leading: const Icon(Icons.history, color: Colors.orange),
                      title: Text(
                        '${context.tr('Corrected')}: $correctedAt',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${context.tr('Reason:')} $reason', style: const TextStyle(fontSize: 12, color: Colors.black)),
                          const SizedBox(height: 2),
                          Text(
                            '${context.tr('Updated status to')}: ${_statusLabel(context, corr['newStatus'] ?? 'PRESENT')}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow({
    required BuildContext context,
    required String title,
    required String time,
    required String date,
    required String location,
    required String source,
    required String status,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(_getSourceIcon(source), size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          _sourceLabel(context, source),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$time ($date)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
