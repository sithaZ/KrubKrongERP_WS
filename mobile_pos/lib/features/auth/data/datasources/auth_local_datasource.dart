import 'dart:convert';
import 'package:erp_mobile/core/constants/app_constants.dart';
import 'package:erp_mobile/core/storage/storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheSession(AuthResponseModel response);
  Future<void> cacheTokens(AuthTokensModel tokens);
  Future<void> cacheUser(UserModel user);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<String?> getRole();
  Future<String?> getCompanyId();
  Future<UserModel?> getLastUser();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._secureStorage);

  final SecureStorageService _secureStorage;

  static const _accessTokenKey = AppConstants.authTokenKey;
  static const _refreshTokenKey = AppConstants.refreshTokenKey;
  static const _roleKey = AppConstants.userRoleKey;
  static const _companyIdKey = AppConstants.companyIdKey;
  static const _userKey = AppConstants.userDataKey;

  @override
  Future<void> cacheSession(AuthResponseModel response) async {
    await cacheTokens(response.tokens);
    await cacheUser(response.user);
    await _secureStorage.write(_roleKey, response.role);

    if (response.companyId != null && response.companyId!.isNotEmpty) {
      await _secureStorage.write(_companyIdKey, response.companyId!);
    } else {
      await _secureStorage.delete(_companyIdKey);
    }
  }

  @override
  Future<void> cacheTokens(AuthTokensModel tokens) async {
    await _secureStorage.write(_accessTokenKey, tokens.accessToken);
    await _secureStorage.write(_refreshTokenKey, tokens.refreshToken);
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await _secureStorage.write(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(_accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(_refreshTokenKey);
  }

  @override
  Future<String?> getRole() async {
    return await _secureStorage.read(_roleKey);
  }

  @override
  Future<String?> getCompanyId() async {
    return await _secureStorage.read(_companyIdKey);
  }

  @override
  Future<UserModel?> getLastUser() async {
    final userJson = await _secureStorage.read(_userKey);
    if (userJson == null) {
      return null;
    }

    return UserModel.fromStorage(jsonDecode(userJson) as Map<String, dynamic>);
  }

  @override
  Future<void> clearCache() async {
    await _secureStorage.deleteAll();
  }
}
