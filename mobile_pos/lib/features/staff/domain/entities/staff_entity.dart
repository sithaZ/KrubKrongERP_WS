import 'package:equatable/equatable.dart';

/// Staff member entity
class StaffMember extends Equatable {

  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
    this.isActive = true,
    this.createdAt,
  });
  final String id;
  final String name;
  final String email;
  final String phone;
  final StaffRole role;
  final String? avatar;
  final bool isActive;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, name, email, role, isActive];

  StaffMember copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    StaffRole? role,
    String? avatar,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum StaffRole {
  admin,
  manager,
  cashier,
}
