import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../domain/entities/employee.dart';
import '../providers/staff_provider.dart';

class AddStaffScreen extends ConsumerStatefulWidget {
  const AddStaffScreen({super.key});

  @override
  ConsumerState<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends ConsumerState<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _positionController = TextEditingController(text: 'Staff');
  final _departmentController = TextEditingController(text: 'General');
  final _salaryController = TextEditingController();
  final _phoneController = TextEditingController();
  String _salaryType = 'monthly';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    _salaryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final employee = Employee(
        id: '',
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        employeeCode: '',
        position: _positionController.text.trim(),
        department: _departmentController.text.trim(),
        salaryType: _salaryType,
        baseSalary: double.tryParse(_salaryController.text) ?? 0.0,
        phone: _phoneController.text.trim(),
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

  void _showSuccessDialog(Map<String, dynamic> credentials) {
    final String email = credentials['email'] ?? 'No email';
    final String password = credentials['temporaryPassword'] ?? 'No password';
    
    ModernAlert.show(
      context,
      title: 'Staff Added Successfully',
      message: 'Please share these login credentials with the employee:\n\n'
          'Login Email: $email\n'
          'Password: $password',
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      confirmLabel: 'Copy & Done',
      onConfirm: () async {
        try {
          final data = 'Login Email: $email\nPassword: $password';
          await Clipboard.setData(ClipboardData(text: data));
          
          if (mounted) {
            // Show toast/snackbar before moving away
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Credentials copied to clipboard!'),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            ref.refresh(employeesProvider);
            // Give the user a moment to see the snackbar before popping
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
        title: const Text('Add New Staff'),
      ),
      body: LoadingOverlay(
        isLoading: staffState.isLoading,
        message: 'Adding employee...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle(theme, 'Personal Information'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),
                _buildSectionTitle(theme, 'Work Information'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _positionController,
                  label: 'Position',
                  icon: Icons.work_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _departmentController,
                  label: 'Department',
                  icon: Icons.business_outlined,
                ),
                const SizedBox(height: 32),
                _buildSectionTitle(theme, 'Salary Details'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _salaryType,
                  decoration: _inputDecoration('Salary Type', Icons.payments_outlined),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  ],
                  onChanged: (v) => setState(() => _salaryType = v!),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _salaryController,
                  label: 'Base Salary',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid amount' : null,
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Create Staff Account', style: TextStyle(fontWeight: FontWeight.bold)),
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
