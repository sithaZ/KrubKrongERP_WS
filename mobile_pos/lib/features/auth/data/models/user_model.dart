import '../../domain/entities/user.dart';

/// User model - data layer representation of User entity
/// Handles serialization/deserialization from API
class UserModel {

  UserModel({
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

  /// Create from GraphQL JSON response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String,
      role: json['role'] as String? ?? 'cashier',
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  /// Create from local storage JSON
  factory UserModel.fromStorage(Map<String, dynamic> json) {
    return UserModel.fromJson(json);
  }
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatar;
  final String? phone;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  /// Convert to domain entity
  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      role: _parseRole(role),
      avatar: avatar,
      phone: phone,
      isActive: isActive,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar': avatar,
      'phone': phone,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'cashier':
      default:
        return UserRole.cashier;
    }
  }
}

/// Auth tokens model
class AuthTokensModel {

  AuthTokensModel({
    required this.token,
    required this.refreshToken,
    this.expiresAt,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: json['expiresAt'] as String?,
    );
  }
  final String token;
  final String refreshToken;
  final String? expiresAt;

  AuthTokens toEntity() {
    return AuthTokens(
      accessToken: token,
      refreshToken: refreshToken,
      expiresAt: expiresAt != null ? DateTime.tryParse(expiresAt!) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt,
    };
  }
}

/// Auth response model (login/register response)
class AuthResponseModel {

  AuthResponseModel({
    required this.tokens,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      tokens: AuthTokensModel.fromJson(json),
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
  final AuthTokensModel tokens;
  final UserModel user;
}
