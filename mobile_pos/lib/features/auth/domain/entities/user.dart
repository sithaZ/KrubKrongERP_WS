import 'package:equatable/equatable.dart';

/// User entity representing the authenticated user
/// This is a domain entity, completely independent of data layer
class User extends Equatable {

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.phone,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatar;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Check if user has admin privileges
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is an owner
  bool get isOwner => role == UserRole.owner;

  /// Check if user is a staff member
  bool get isStaff => role == UserRole.staff;

  /// Get display name (name or email prefix)
  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  /// Get initials for avatar placeholder
  String get initials {
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
    role,
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
    UserRole? role,
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
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// User roles enum
enum UserRole {
  admin,
  owner,
  staff,
}

/// Auth tokens entity
class AuthTokens extends Equatable {

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
  });
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;

  /// Check if token is expired (with 5 minute buffer)
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!.subtract(const Duration(minutes: 5)));
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt];
}

/// Login credentials value object
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

/// Register credentials value object
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
