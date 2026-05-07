import '../../domain/entities/user.dart';

class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.companyId,
    this.avatar,
    this.phone,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final companyIdValue = json['companyId'];

    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      companyId: companyIdValue?.toString(),
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  factory UserModel.fromStorage(Map<String, dynamic> json) {
    return UserModel.fromJson(json);
  }

  final String id;
  final String name;
  final String email;
  final String role;
  final String? companyId;
  final String? avatar;
  final String? phone;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      rawRole: role,
      role: _parseRole(role),
      companyId: companyId,
      avatar: avatar,
      phone: phone,
      isActive: isActive,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'companyId': companyId,
      'avatar': avatar,
      'phone': phone,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserRole? _parseRole(String role) {
    final r = role.toUpperCase();
    if (r == 'MANAGER' || r == 'OWNER' || r == 'ADMIN') {
      return UserRole.manager;
    }
    if (r == 'EMPLOYEE' || r == 'STAFF') {
      return UserRole.employee;
    }
    return null;
  }
}

class AuthTokensModel {
  AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken:
          json['accessToken'] as String? ??
          json['access_token'] as String? ??
          json['token'] as String? ??
          '',
      refreshToken: json['refreshToken'] as String? ??
          json['accessToken'] as String? ??
          json['refresh_token'] as String? ??
          json['access_token'] as String? ??
          json['token'] as String? ??
          '',
      expiresAt: json['expiresAt'] as String?,
    );
  }

  final String accessToken;
  final String refreshToken;
  final String? expiresAt;

  AuthTokens toEntity() {
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt != null ? DateTime.tryParse(expiresAt!) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt,
    };
  }
}

class AuthResponseModel {
  AuthResponseModel({
    required this.tokens,
    required this.user,
    required this.role,
    this.companyId,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = (json['user'] as Map<String, dynamic>?) ?? {};
    final topLevelRole = json['role'] as String?;
    final topLevelCompanyId = json['companyId']?.toString();

    return AuthResponseModel(
      tokens: AuthTokensModel.fromJson(json),
      user: UserModel.fromJson({
        ...userJson,
        if (!userJson.containsKey('role') && topLevelRole != null)
          'role': topLevelRole,
        if (!userJson.containsKey('companyId') && topLevelCompanyId != null)
          'companyId': topLevelCompanyId,
      }),
      role: topLevelRole ?? userJson['role'] as String? ?? '',
      companyId: topLevelCompanyId ?? userJson['companyId']?.toString(),
    );
  }

  final AuthTokensModel tokens;
  final UserModel user;
  final String role;
  final String? companyId;
}
