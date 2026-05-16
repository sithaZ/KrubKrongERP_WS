import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.rawRole,
    this.role,
    this.companyId,
    this.avatar,
    this.phone,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String rawRole;
  final UserRole? role;
  final String? companyId;
  final String? avatar;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isManager => role == UserRole.manager;

  bool get isEmployee => role == UserRole.employee;

  bool get hasSupportedRole => role != null;

  bool get isAdmin => rawRole.toUpperCase() == 'ADMIN';

  bool get isOwner => isManager || isAdmin;

  bool get isStaff => isEmployee;

  String get roleLabel => rawRole.toUpperCase();

  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  String get initials {
    if (name.isEmpty) {
      return 'U';
    }

    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }

    return name.substring(0, 1).toUpperCase();
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        rawRole,
        role,
        companyId,
        avatar,
        phone,
        isActive,
        createdAt,
        updatedAt,
      ];

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? rawRole,
    UserRole? role,
    String? companyId,
    String? avatar,
    String? phone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      rawRole: rawRole ?? this.rawRole,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum UserRole {
  manager,
  employee,
}

class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;

  bool get isExpired {
    if (expiresAt == null) {
      return false;
    }

    return DateTime.now()
        .isAfter(expiresAt!.subtract(const Duration(minutes: 5)));
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt];
}

class LoginCredentials extends Equatable {
  const LoginCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class RegisterCredentials extends Equatable {
  const RegisterCredentials({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  final String name;
  final String email;
  final String password;
  final String? phone;

  @override
  List<Object?> get props => [name, email, password, phone];
}
