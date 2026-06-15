import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/core.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../domain/entities/employee.dart';
import '../providers/staff_provider.dart';
import '../../../attendance/data/services/attendance_service.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AddStaffScreen extends ConsumerStatefulWidget {
  const AddStaffScreen({super.key});

  @override
  ConsumerState<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends ConsumerState<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _salaryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hireDateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );

  String _salaryType = 'monthly';
  DateTime? _selectedHireDate = DateTime.now();

  // Positions & Departments Dynamic State
  List<String> _positions = ['Staff', 'Cashier', 'Manager'];
  List<String> _defaultPositions = ['Staff', 'Cashier'];
  List<String> _departments = ['General', 'Front House', 'Kitchen'];
  List<String> _defaultDepartments = ['General', 'Front House'];

  List<String> _allowedPositions = [];
  List<String> _allowedDepartments = [];

  String _selectedPosition = 'Staff';
  String _selectedDepartment = 'General';

  // Shifts state
  List<dynamic> _shifts = [];
  String? _selectedShiftId;
  bool _loadingShifts = false;
  bool _isOwner = false;
  String _startTime = '08:00';
  String _endTime = '17:00';

  @override
  void initState() {
    super.initState();
    _loadSettingsAndShifts();
  }

  Future<void> _loadSettingsAndShifts() async {
    final prefs = await SharedPreferences.getInstance();
    final authState = ref.read(authProvider);
    final user = authState.user;
    _isOwner = (user?.isOwner ?? false) || (user?.isAdmin ?? false);

    // Dynamic Lists loaded from SharedPreferences
    setState(() {
      _positions = prefs.getStringList('erp_positions') ?? ['Staff', 'Cashier', 'Manager'];
      _defaultPositions = prefs.getStringList('erp_manager_default_positions') ?? ['Staff', 'Cashier'];
      _departments = prefs.getStringList('erp_departments') ?? ['General', 'Front House', 'Kitchen'];
      _defaultDepartments = prefs.getStringList('erp_manager_default_departments') ?? ['General', 'Front House'];

      if (!_isOwner) {
        // Managers can ONLY select from the Owner's ticked defaults!
        _allowedPositions = List<String>.from(_defaultPositions);
        _allowedDepartments = List<String>.from(_defaultDepartments);
      } else {
        // Owners can select all options
        _allowedPositions = List<String>.from(_positions);
        _allowedDepartments = List<String>.from(_departments);
      }

      if (_allowedPositions.isNotEmpty && !_allowedPositions.contains(_selectedPosition)) {
        _selectedPosition = _allowedPositions.first;
      }
      if (_allowedDepartments.isNotEmpty && !_allowedDepartments.contains(_selectedDepartment)) {
        _selectedDepartment = _allowedDepartments.first;
      }
    });

    // Load shifts from backend
    setState(() => _loadingShifts = true);
    try {
      final service = ref.read(attendanceServiceProvider);
      final shiftsList = await service.getAllShifts();
      setState(() {
        _shifts = shiftsList;
        // Pre-select first active shift if available
        final activeShifts = _shifts.where((s) => s['isActive'] == true).toList();
        if (activeShifts.isNotEmpty) {
          _selectedShiftId = activeShifts.first['_id'];
        } else if (_shifts.isNotEmpty) {
          _selectedShiftId = _shifts.first['_id'];
        }
        
        if (_selectedShiftId != null) {
          final sel = _shifts.firstWhere((s) => s['_id'] == _selectedShiftId);
          _startTime = sel['startTime'] ?? '08:00';
          _endTime = sel['endTime'] ?? '17:00';
        }
      });
    } catch (e) {
      debugPrint('Error loading shifts: $e');
    } finally {
      setState(() => _loadingShifts = false);
    }
  }

  Future<void> _selectHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedHireDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedHireDate = picked;
        _hireDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _addNewPosition() async {
    final textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr('Add Custom Position')),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              labelText: context.tr('Position Name'),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final val = textController.text.trim();
                if (val.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  setState(() {
                    if (!_positions.contains(val)) {
                      _positions.add(val);
                      _allowedPositions.add(val);
                      // By default, check it for managers
                      _defaultPositions.add(val);
                    }
                    _selectedPosition = val;
                  });
                  await prefs.setStringList('erp_positions', _positions);
                  await prefs.setStringList('erp_manager_default_positions', _defaultPositions);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Text(context.tr('Add')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNewDepartment() async {
    final textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr('Add Custom Department')),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              labelText: context.tr('Department Name'),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final val = textController.text.trim();
                if (val.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  setState(() {
                    if (!_departments.contains(val)) {
                      _departments.add(val);
                      _allowedDepartments.add(val);
                      _defaultDepartments.add(val);
                    }
                    _selectedDepartment = val;
                  });
                  await prefs.setStringList('erp_departments', _departments);
                  await prefs.setStringList('erp_manager_default_departments', _defaultDepartments);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Text(context.tr('Add')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNewShift() async {
    final nameController = TextEditingController();
    String start = '08:00';
    String end = '17:00';
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selectDTime(bool isStart) async {
              final initialTime = _parseTimeString(isStart ? start : end);
              final picked = await showTimePicker(
                context: context,
                initialTime: initialTime,
              );
              if (picked != null) {
                setDialogState(() {
                  final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  if (isStart) {
                    start = formatted;
                  } else {
                    end = formatted;
                  }
                });
              }
            }

            return AlertDialog(
              title: Text(context.tr('Add Shift Template')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: context.tr('Shift Name (e.g. Morning, Afternoon)'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => selectDTime(true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: context.tr('Start Time'),
                              prefixIcon: Icon(Icons.login_rounded),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_formatTimeForDisplay(start)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => selectDTime(false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: context.tr('End Time'),
                              prefixIcon: Icon(Icons.logout_rounded),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_formatTimeForDisplay(end)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('Cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    
                    try {
                      final service = ref.read(attendanceServiceProvider);
                      final newShift = await service.createShift({
                        'shiftName': name,
                        'startTime': start,
                        'endTime': end,
                        'gracePeriodMinutes': 15,
                        'breakMinutes': 60,
                        'isActive': true,
                      });
                      
                      setState(() {
                        _shifts.add(newShift);
                        _selectedShiftId = newShift['_id'] ?? newShift['id'];
                        _startTime = start;
                        _endTime = end;
                      });
                      
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      debugPrint('Error creating shift template: $e');
                    }
                  },
                  child: Text(context.tr('Add Template')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    _phoneController.dispose();
    _hireDateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _loadingShifts = true);
      String? finalShiftId = _selectedShiftId;

      try {
        if (_selectedShiftId != null) {
          final selectedShift = _shifts.firstWhere((s) => s['_id'] == _selectedShiftId);
          final defaultStart = selectedShift['startTime'] ?? '00:00';
          final defaultEnd = selectedShift['endTime'] ?? '00:00';

          if (defaultStart != _startTime || defaultEnd != _endTime) {
            // Shift timings differ from the default shift settings, create a custom shift
            final service = ref.read(attendanceServiceProvider);
            final newShift = await service.createShift({
              'shiftName': '${selectedShift['shiftName'] ?? 'Shift'} (Custom)',
              'startTime': _startTime,
              'endTime': _endTime,
              'gracePeriodMinutes': selectedShift['gracePeriodMinutes'] ?? 15,
              'breakMinutes': selectedShift['breakMinutes'] ?? 60,
              'isActive': false, // Hide from standard shift list
            });
            finalShiftId = newShift['_id'] ?? newShift['id'];
          }
        }
      } catch (e) {
        debugPrint('Error creating customized shift: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${context.tr('Failed to customize shift timing:')} $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _loadingShifts = false);
        return;
      }

      setState(() => _loadingShifts = false);

      final employee = Employee(
        id: '',
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        employeeCode: '',
        position: _selectedPosition,
        department: _selectedDepartment,
        salaryType: _salaryType,
        baseSalary: double.tryParse(_salaryController.text) ?? 0.0,
        phone: _phoneController.text.trim(),
        isActive: true,
        hireDate: _selectedHireDate,
        shiftId: finalShiftId,
      );

      ref.read(staffNotifierProvider.notifier).addEmployee(
        employee,
        (data) {
          final credentials = data['credentials'] as Map<String, dynamic>;
          _showSuccessDialog(credentials);
        },
      );
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = _parseTimeString(isStart ? _startTime : _endTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          _startTime = formatted;
        } else {
          _endTime = formatted;
        }
      });
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  String _formatTimeForDisplay(String timeStr) {
    final time = _parseTimeString(timeStr);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _showSuccessDialog(Map<String, dynamic> credentials) {
    final String email = credentials['email'] ?? 'No email';
    final String password = credentials['temporaryPassword'] ?? 'No password';

    ModernAlert.show(
      context,
      title: context.tr('Staff Added Successfully'),
      message: '${context.tr('Please share these login credentials with the employee:')}\n\n'
          'Login Email: $email\n'
          'Password: $password',
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      confirmLabel: context.tr('Copy & Done'),
      onConfirm: () async {
        try {
          final data = 'Login Email: $email\nPassword: $password';
          await Clipboard.setData(ClipboardData(text: data));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('Credentials copied to clipboard!')),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );

            ref.refresh(employeesProvider);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) context.pop();
            });
          }
        } catch (e) {
          debugPrint('Clipboard error: $e');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Add New Staff')),
      ),
      body: LoadingOverlay(
        isLoading: staffState.isLoading || _loadingShifts,
        message: context.tr('Loading metadata & onboarding staff...'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle(theme, context.tr('Personal Information')),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: context.tr('Full Name'),
                  icon: Icons.person_outline,
                  validator: (v) => v?.isEmpty ?? true ? context.tr('Required') : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: context.tr('Email Address'),
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: context.tr('Phone Number (Optional)'),
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                // Hire Date DatePicker
                TextFormField(
                  controller: _hireDateController,
                  readOnly: true,
                  onTap: _selectHireDate,
                  decoration: _inputDecoration(context.tr('Hire Date'), Icons.calendar_today),
                ),
                const SizedBox(height: 32),

                _buildSectionTitle(theme, context.tr('Work & Scheduling Info')),
                const SizedBox(height: 16),

                // Shift Selection Dropdown
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedShiftId,
                        decoration: _inputDecoration(context.tr('Assign Shift'), Icons.schedule),
                        items: _shifts.where((s) => s['isActive'] == true).map((s) {
                          final name = s['shiftName'] ?? 'Shift';
                          final start = s['startTime'] ?? '00:00';
                          final end = s['endTime'] ?? '00:00';
                          return DropdownMenuItem<String>(
                            value: s['_id'],
                            child: Text('$name ($start - $end)'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedShiftId = v;
                            if (v != null) {
                              final sel = _shifts.firstWhere((s) => s['_id'] == v);
                              _startTime = sel['startTime'] ?? '08:00';
                              _endTime = sel['endTime'] ?? '17:00';
                            }
                          });
                        },
                        validator: (v) => v == null ? context.tr('Please assign a shift') : null,
                      ),
                    ),
                    if (_isOwner) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        tooltip: context.tr('Add Custom Shift Template'),
                        onPressed: _addNewShift,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedShiftId != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(true),
                          child: InputDecorator(
                            decoration: _inputDecoration(context.tr('Shift Start Time'), Icons.login_rounded),
                            child: Text(
                              _formatTimeForDisplay(_startTime),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(false),
                          child: InputDecorator(
                            decoration: _inputDecoration(context.tr('Shift End Time'), Icons.logout_rounded),
                            child: Text(
                              _formatTimeForDisplay(_endTime),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Position Dropdown + Add Position
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPosition.isNotEmpty && _allowedPositions.contains(_selectedPosition)
                            ? _selectedPosition
                            : (_allowedPositions.isNotEmpty ? _allowedPositions.first : null),
                        decoration: _inputDecoration(context.tr('Position'), Icons.work_outline),
                        items: _allowedPositions.map((pos) {
                          return DropdownMenuItem<String>(
                            value: pos,
                            child: Text(pos),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedPosition = v);
                        },
                      ),
                    ),
                    if (_isOwner) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        tooltip: context.tr('Add Custom Position'),
                        onPressed: _addNewPosition,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Department Dropdown + Add Department
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDepartment.isNotEmpty && _allowedDepartments.contains(_selectedDepartment)
                            ? _selectedDepartment
                            : (_allowedDepartments.isNotEmpty ? _allowedDepartments.first : null),
                        decoration: _inputDecoration(context.tr('Department'), Icons.business_outlined),
                        items: _allowedDepartments.map((dept) {
                          return DropdownMenuItem<String>(
                            value: dept,
                            child: Text(dept),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedDepartment = v);
                        },
                      ),
                    ),
                    if (_isOwner) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        tooltip: context.tr('Add Custom Department'),
                        onPressed: _addNewDepartment,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),

                // Owner Settings Checkboxes for Manager Defaults
                if (_isOwner) ...[
                  _buildSectionTitle(theme, context.tr('Default Settings (Options for Managers)')),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('Select which positions and departments your managers are allowed to assign to new staff:'),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              context.tr('Allowed Positions:'),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                            ),
                          ),
                          ..._positions.map((pos) {
                            final isTicked = _defaultPositions.contains(pos);
                            return CheckboxListTile(
                              dense: true,
                              title: Text(pos),
                              value: isTicked,
                              onChanged: (val) async {
                                final prefs = await SharedPreferences.getInstance();
                                setState(() {
                                  if (val == true) {
                                    _defaultPositions.add(pos);
                                  } else {
                                    _defaultPositions.remove(pos);
                                  }
                                });
                                await prefs.setStringList('erp_manager_default_positions', _defaultPositions);
                              },
                            );
                          }),
                          const Divider(),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              context.tr('Allowed Departments:'),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                            ),
                          ),
                          ..._departments.map((dept) {
                            final isTicked = _defaultDepartments.contains(dept);
                            return CheckboxListTile(
                              dense: true,
                              title: Text(dept),
                              value: isTicked,
                              onChanged: (val) async {
                                final prefs = await SharedPreferences.getInstance();
                                setState(() {
                                  if (val == true) {
                                    _defaultDepartments.add(dept);
                                  } else {
                                    _defaultDepartments.remove(dept);
                                  }
                                });
                                await prefs.setStringList('erp_manager_default_departments', _defaultDepartments);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                _buildSectionTitle(theme, context.tr('Salary Details')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _salaryType,
                  decoration: _inputDecoration(context.tr('Salary Type'), Icons.payments_outlined),
                  items: [
                    DropdownMenuItem(value: 'monthly', child: Text(context.tr('Monthly'))),
                    DropdownMenuItem(value: 'daily', child: Text(context.tr('Daily'))),
                  ],
                  onChanged: (v) => setState(() => _salaryType = v!),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _salaryController,
                  label: context.tr('Base Salary'),
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v ?? '') == null ? context.tr('Invalid amount') : null,
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    context.tr('Create Staff Account'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (staffState.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    staffState.error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}
