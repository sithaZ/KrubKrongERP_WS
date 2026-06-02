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

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _saving = true);
      
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
        shiftId: _selectedShiftId,
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
                    if (_shifts.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedShiftId,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Shift Duration',
                          prefixIcon: Icon(Icons.schedule),
                          border: OutlineInputBorder(),
                        ),
                        items: _shifts.map((s) {
                          final name = s['shiftName'] ?? 'Shift';
                          final start = s['startTime'] ?? '00:00';
                          final end = s['endTime'] ?? '00:00';
                          return DropdownMenuItem<String>(
                            value: s['_id'],
                            child: Text('$name ($start - $end)'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedShiftId = v),
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
