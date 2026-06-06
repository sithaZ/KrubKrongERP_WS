import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../app/router/route_paths.dart';
import '../providers/staff_provider.dart';
import '../../../attendance/data/services/attendance_service.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/employee.dart';

/// Staff management screen
class StaffScreen extends ConsumerWidget {
  const StaffScreen({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final body = employeesAsync.when(
      data: (employees) {
        if (employees.isEmpty) {
          return EmptyStateWidget(
            message: 'No staff yet',
            subMessage: 'Add your first team member to get started.',
            icon: Icons.people_outline_rounded,
            action: ElevatedButton.icon(
              onPressed: () => context.push(AppRoutePaths.addStaff),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Staff'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(employeesProvider.future),
          color: AppTheme.primary,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: employees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final employee = employees[index];
              return _EmployeeCard(employee: employee, isDark: isDark);
            },
          ),
        );
      },
      loading: () => const AppLoadingIndicator(),
      error: (error, _) => AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.refresh(employeesProvider),
      ),
    );

    if (!showAppBar) return body;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutePaths.addStaff),
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Staff',
          ),
        ],
      ),
      body: body,
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee, required this.isDark});
  final dynamic employee;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = employee.isActive as bool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.primary, Color(0xFF1A3BA0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                (employee.fullName as String).substring(0, 1).toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        employee.fullName as String,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    StatusBadge(
                      label: isActive ? 'Active' : 'Inactive',
                      color: isActive ? AppTheme.success : AppTheme.error,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 12,
                      color: isDark ? AppTheme.darkTextDisabled : AppTheme.lightTextDisabled,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      employee.employeeCode as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.work_outline_rounded,
                      size: 12,
                      color: isDark ? AppTheme.darkTextDisabled : AppTheme.lightTextDisabled,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        employee.position as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (employee.shiftName != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: isDark ? AppTheme.darkTextDisabled : AppTheme.lightTextDisabled,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${employee.shiftName} (${employee.shiftStartTime} - ${employee.shiftEndTime})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Actions Menu Popup
          Consumer(
            builder: (context, ref, _) {
              return PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  size: 20,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    showDialog(
                      context: context,
                      builder: (context) => EditStaffDialog(employee: employee),
                    );
                  } else if (value == 'toggle_active') {
                    _confirmToggleActive(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('Edit Staff'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_active',
                    child: Row(
                      children: [
                        Icon(isActive ? Icons.lock_outline : Icons.lock_open_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmToggleActive(BuildContext context, WidgetRef ref) {
    final isActive = employee.isActive as bool;
    ModernAlert.show(
      context,
      title: isActive ? 'Deactivate Staff' : 'Activate Staff',
      message: isActive 
          ? 'Are you sure you want to deactivate ${employee.fullName}? They will no longer be able to log in.'
          : 'Are you sure you want to activate ${employee.fullName}? They will be allowed to log in.',
      confirmLabel: isActive ? 'Deactivate' : 'Activate',
      cancelLabel: 'Cancel',
      icon: Icons.warning_amber_rounded,
      iconColor: isActive ? AppTheme.error : AppTheme.success,
      onConfirm: () async {
        if (isActive) {
          await ref.read(staffNotifierProvider.notifier).deactivateEmployee(employee.id);
        } else {
          final updated = (employee as Employee).copyWith(isActive: true);
          await ref.read(staffNotifierProvider.notifier).updateEmployee(updated, () {});
        }
        ref.refresh(employeesProvider);
      },
    );
  }
}

class EditStaffDialog extends ConsumerStatefulWidget {
  final dynamic employee;
  const EditStaffDialog({super.key, required this.employee});

  @override
  ConsumerState<EditStaffDialog> createState() => _EditStaffDialogState();
}

class _EditStaffDialogState extends ConsumerState<EditStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _salaryController;
  late TextEditingController _phoneController;
  late TextEditingController _hireDateController;

  late String _salaryType;
  late bool _isActive;
  late DateTime? _selectedHireDate;

  List<String> _positions = ['Staff', 'Cashier', 'Manager'];
  List<String> _defaultPositions = ['Staff', 'Cashier'];
  List<String> _departments = ['General', 'Front House', 'Kitchen'];
  List<String> _defaultDepartments = ['General', 'Front House'];

  List<String> _allowedPositions = [];
  List<String> _allowedDepartments = [];

  late String _selectedPosition;
  late String _selectedDepartment;

  List<dynamic> _shifts = [];
  String? _selectedShiftId;
  bool _loadingShifts = false;
  bool _isOwner = false;
  bool _saving = false;
  String _startTime = '08:00';
  String _endTime = '17:00';

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _nameController = TextEditingController(text: emp.fullName);
    _salaryController = TextEditingController(text: emp.baseSalary.toString());
    _phoneController = TextEditingController(text: emp.phone ?? '');
    
    _salaryType = emp.salaryType;
    _isActive = emp.isActive;
    _selectedHireDate = emp.hireDate;
    _hireDateController = TextEditingController(
      text: _selectedHireDate != null 
          ? DateFormat('yyyy-MM-dd').format(_selectedHireDate!) 
          : '',
    );
    _selectedPosition = emp.position;
    _selectedDepartment = emp.department;
    _selectedShiftId = emp.shiftId;

    _loadSettingsAndShifts();
  }

  Future<void> _loadSettingsAndShifts() async {
    final prefs = await SharedPreferences.getInstance();
    final authState = ref.read(authProvider);
    final user = authState.user;
    _isOwner = (user?.isOwner ?? false) || (user?.isAdmin ?? false);

    setState(() {
      _positions = prefs.getStringList('erp_positions') ?? ['Staff', 'Cashier', 'Manager'];
      _defaultPositions = prefs.getStringList('erp_manager_default_positions') ?? ['Staff', 'Cashier'];
      _departments = prefs.getStringList('erp_departments') ?? ['General', 'Front House', 'Kitchen'];
      _defaultDepartments = prefs.getStringList('erp_manager_default_departments') ?? ['General', 'Front House'];

      if (!_isOwner) {
        _allowedPositions = List<String>.from(_defaultPositions);
        _allowedDepartments = List<String>.from(_defaultDepartments);
      } else {
        _allowedPositions = List<String>.from(_positions);
        _allowedDepartments = List<String>.from(_departments);
      }

      // Safeguard in case existing position/dept is not in current metadata lists
      if (!_allowedPositions.contains(_selectedPosition)) {
        _allowedPositions.add(_selectedPosition);
      }
      if (!_allowedDepartments.contains(_selectedDepartment)) {
        _allowedDepartments.add(_selectedDepartment);
      }
    });

    setState(() => _loadingShifts = true);
    try {
      final service = ref.read(attendanceServiceProvider);
      final shiftsList = await service.getAllShifts();
      setState(() {
        _shifts = shiftsList;
        if (_selectedShiftId != null) {
          final sel = _shifts.firstWhere(
            (s) => s['_id'] == _selectedShiftId,
            orElse: () => null,
          );
          if (sel != null) {
            _startTime = sel['startTime'] ?? '08:00';
            _endTime = sel['endTime'] ?? '17:00';
          }
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

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _saving = true);
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
              content: Text('Failed to customize shift timing: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _saving = false);
        return;
      }
      
      final currentEmp = widget.employee as Employee;
      final updated = currentEmp.copyWith(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        position: _selectedPosition,
        department: _selectedDepartment,
        salaryType: _salaryType,
        baseSalary: double.tryParse(_salaryController.text) ?? 0.0,
        isActive: _isActive,
        hireDate: _selectedHireDate,
        shiftId: finalShiftId,
      );

      ref.read(staffNotifierProvider.notifier).updateEmployee(
        updated,
        () {
          setState(() => _saving = false);
          ref.refresh(employeesProvider);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff record updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
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
              title: const Text('Add Shift Template'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Shift Name (e.g. Morning, Afternoon)',
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
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
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
                            decoration: const InputDecoration(
                              labelText: 'End Time',
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
                  child: const Text('Cancel'),
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
                  child: const Text('Add Template'),
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
    _salaryController.dispose();
    _phoneController.dispose();
    _hireDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit_note, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text('Edit ${widget.employee.fullName}')),
        ],
      ),
      content: _loadingShifts 
          ? const SizedBox(
              height: 100, 
              child: Center(child: CircularProgressIndicator())
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Active Toggle Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Login Authorization'),
                      subtitle: Text(_isActive ? 'Active (Allowed to log in)' : 'Inactive (Access Blocked)'),
                      value: _isActive,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        setState(() => _isActive = val);
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hireDateController,
                      readOnly: true,
                      onTap: _selectHireDate,
                      decoration: const InputDecoration(
                        labelText: 'Hire Date',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Shifts Dropdown
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedShiftId,
                            decoration: const InputDecoration(
                              labelText: 'Assigned Shift Duration',
                              prefixIcon: Icon(Icons.schedule),
                              border: OutlineInputBorder(),
                            ),
                            items: _shifts.where((s) => s['isActive'] == true || s['_id'] == _selectedShiftId).map((s) {
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
                          ),
                        ),
                        if (_isOwner) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blue),
                            tooltip: 'Add Custom Shift Template',
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
                                decoration: const InputDecoration(
                                  labelText: 'Shift Start Time',
                                  prefixIcon: Icon(Icons.login_rounded),
                                  border: OutlineInputBorder(),
                                ),
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
                                decoration: const InputDecoration(
                                  labelText: 'Shift End Time',
                                  prefixIcon: Icon(Icons.logout_rounded),
                                  border: OutlineInputBorder(),
                                ),
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

                    // Position Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedPosition,
                      decoration: const InputDecoration(
                        labelText: 'Position',
                        prefixIcon: Icon(Icons.work_outline),
                        border: OutlineInputBorder(),
                      ),
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
                    const SizedBox(height: 16),

                    // Department Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(Icons.business_outlined),
                        border: OutlineInputBorder(),
                      ),
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
                    const SizedBox(height: 16),

                    // Salary Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _salaryType,
                      decoration: const InputDecoration(
                        labelText: 'Salary Type',
                        prefixIcon: Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      ],
                      onChanged: (v) => setState(() => _salaryType = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _salaryController,
                      decoration: const InputDecoration(
                        labelText: 'Base Salary',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid amount' : null,
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving 
              ? const SizedBox(
                  height: 16, 
                  width: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
