import '../../domain/entities/employee.dart';

/// Employee model for data serialization
class EmployeeModel {
  EmployeeModel({
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
    this.shiftId,
    this.shiftName,
    this.shiftStartTime,
    this.shiftEndTime,
    this.shiftGracePeriodMinutes,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final shiftMap = json['shiftId'] is Map ? json['shiftId'] as Map<String, dynamic> : null;
    return EmployeeModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? '',
      position: json['position'] as String? ?? 'staff',
      department: json['department'] as String? ?? 'general',
      salaryType: json['salaryType'] as String? ?? 'monthly',
      baseSalary: (json['baseSalary'] as num? ?? 0).toDouble(),
      userId: json['userId'] is Map
          ? (json['userId'] as Map<String, dynamic>)['id'] as String? ??
            (json['userId'] as Map<String, dynamic>)['_id'] as String?
          : json['userId'] as String?,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      hireDate: json['hireDate'] != null ? DateTime.tryParse(json['hireDate'] as String) : null,
      shiftId: shiftMap != null
          ? (shiftMap['id'] as String? ?? shiftMap['_id'] as String?)
          : json['shiftId'] as String?,
      shiftName: shiftMap?['shiftName'] as String?,
      shiftStartTime: shiftMap?['startTime'] as String?,
      shiftEndTime: shiftMap?['endTime'] as String?,
      shiftGracePeriodMinutes: shiftMap?['gracePeriodMinutes'] as int?,
    );
  }

  final String id;
  final String fullName;
  final String email;
  final String employeeCode;
  final String position;
  final String department;
  final String salaryType;
  final double baseSalary;
  final String? userId;
  final String? phone;
  final bool isActive;
  final DateTime? hireDate;
  final String? shiftId;
  final String? shiftName;
  final String? shiftStartTime;
  final String? shiftEndTime;
  final int? shiftGracePeriodMinutes;

  Employee toEntity() {
    return Employee(
      id: id,
      fullName: fullName,
      email: email,
      employeeCode: employeeCode,
      position: position,
      department: department,
      salaryType: salaryType,
      baseSalary: baseSalary,
      userId: userId,
      phone: phone,
      isActive: isActive,
      hireDate: hireDate,
      shiftId: shiftId,
      shiftName: shiftName,
      shiftStartTime: shiftStartTime,
      shiftEndTime: shiftEndTime,
      shiftGracePeriodMinutes: shiftGracePeriodMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'position': position,
      'department': department,
      'salaryType': salaryType,
      'baseSalary': baseSalary,
      'phone': phone,
      'isActive': isActive,
      'hireDate': hireDate?.toIso8601String(),
      'shiftId': shiftId,
    };
  }
}
