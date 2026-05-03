import 'package:equatable/equatable.dart';

/// Employee domain entity
class Employee extends Equatable {
  const Employee({
    required this.id,
    required this.fullName,
    required this.email,
    required this.employeeCode,
    required this.position,
    required this.department,
    required this.salaryType,
    required this.baseSalary,
    this.userId,
    this.phone,
    this.isActive = true,
    this.hireDate,
  });

  final String id;
  final String fullName;
  final String email;
  final String employeeCode;
  final String position;
  final String department;
  final String salaryType; // 'daily' | 'monthly'
  final double baseSalary;
  final String? userId;
  final String? phone;
  final bool isActive;
  final DateTime? hireDate;

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        employeeCode,
        position,
        department,
        salaryType,
        baseSalary,
        userId,
        phone,
        isActive,
        hireDate,
      ];

  Employee copyWith({
    String? id,
    String? fullName,
    String? email,
    String? employeeCode,
    String? position,
    String? department,
    String? salaryType,
    double? baseSalary,
    String? userId,
    String? phone,
    bool? isActive,
    DateTime? hireDate,
  }) {
    return Employee(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      employeeCode: employeeCode ?? this.employeeCode,
      position: position ?? this.position,
      department: department ?? this.department,
      salaryType: salaryType ?? this.salaryType,
      baseSalary: baseSalary ?? this.baseSalary,
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      hireDate: hireDate ?? this.hireDate,
    );
  }
}
