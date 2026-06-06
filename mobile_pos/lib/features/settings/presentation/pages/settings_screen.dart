import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/errors/failures.dart';
import '../../../attendance/data/services/attendance_service.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Shop details
  final _shopNameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController();
  final _secretKeyController = TextEditingController();

  // Self-attendance toggles
  bool _allowManagerSelfAttendance = false;
  bool _allowStaffSelfAttendance = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final service = ref.read(attendanceServiceProvider);
      final settings = await service.getShopSettings();
      setState(() {
        _shopNameController.text = settings['shopName'] ?? 'Default Shop';
        final coords = settings['coordinates'] as Map<String, dynamic>? ?? {};
        _latController.text = (coords['lat'] ?? 0).toString();
        _lngController.text = (coords['lng'] ?? 0).toString();
        _radiusController.text = (settings['radius'] ?? 50).toString();
        _secretKeyController.text = settings['secretKey'] ?? '';
        _allowManagerSelfAttendance = settings['allowManagerSelfAttendance'] ?? false;
        _allowStaffSelfAttendance = settings['allowStaffSelfAttendance'] ?? false;
      });
    } catch (e) {
      debugPrint('Error loading shop settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(attendanceServiceProvider);
      await service.updateShopSettings({
        'shopName': _shopNameController.text.trim(),
        'coordinates': {
          'lat': double.tryParse(_latController.text) ?? 0,
          'lng': double.tryParse(_lngController.text) ?? 0,
        },
        'radius': int.tryParse(_radiusController.text) ?? 50,
        'secretKey': _secretKeyController.text.trim(),
        'allowManagerSelfAttendance': _allowManagerSelfAttendance,
        'allowStaffSelfAttendance': _allowStaffSelfAttendance,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final message = e is Failure ? e.message : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Settings'),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── SHOP DETAILS SECTION ──
                    _buildSectionHeader(
                      theme,
                      icon: Icons.store_rounded,
                      title: 'Shop Details',
                      subtitle: 'Basic shop information used for attendance tracking.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _shopNameController,
                      decoration: _inputDecoration('Shop Name', Icons.storefront_rounded),
                      validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            decoration: _inputDecoration('Latitude', Icons.my_location_rounded),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            decoration: _inputDecoration('Longitude', Icons.my_location_rounded),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _radiusController,
                      decoration: _inputDecoration('Attendance Radius (meters)', Icons.radar_rounded),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _secretKeyController,
                      decoration: _inputDecoration('QR Secret Key', Icons.vpn_key_rounded),
                      validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                    ),

                    const SizedBox(height: 32),

                    // ── SELF-ATTENDANCE SECTION ──
                    _buildSectionHeader(
                      theme,
                      icon: Icons.fingerprint_rounded,
                      title: 'Self-Attendance Settings',
                      subtitle: 'Allow employees to clock in without scanning a QR code. GPS location is still verified.',
                    ),
                    const SizedBox(height: 16),
                    _buildToggleCard(
                      theme: theme,
                      isDark: isDark,
                      icon: Icons.admin_panel_settings_rounded,
                      iconColor: Colors.deepPurple,
                      title: 'Manager Self-Attendance',
                      subtitle: 'Managers can clock in/out with just GPS verification (no QR code from owner needed).',
                      value: _allowManagerSelfAttendance,
                      onChanged: (v) => setState(() => _allowManagerSelfAttendance = v),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleCard(
                      theme: theme,
                      isDark: isDark,
                      icon: Icons.person_rounded,
                      iconColor: Colors.blue,
                      title: 'Staff Self-Attendance',
                      subtitle: 'Staff can clock in/out with GPS when manager is absent or on day off.',
                      value: _allowStaffSelfAttendance,
                      onChanged: (v) => setState(() => _allowStaffSelfAttendance = v),
                    ),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Self-attendance still requires the employee to be within the shop\'s GPS radius. Only the QR code scanning step is bypassed.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, {required IconData icon, required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 22, color: AppTheme.primary),
            const SizedBox(width: 10),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? iconColor.withOpacity(0.4)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        boxShadow: value
            ? [BoxShadow(color: iconColor.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
