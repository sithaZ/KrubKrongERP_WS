import 'dart:convert';
import 'package:erp_mobile/core/constants/app_constants.dart';
import 'package:erp_mobile/core/storage/storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheTokens(AuthTokensModel tokens);
  Future<void> cacheUser(UserModel user);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<UserModel?> getLastUser();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._secureStorage);
  final SecureStorageService _secureStorage;

  static const _accessTokenKey = AppConstants.authTokenKey;
  static const _refreshTokenKey = AppConstants.refreshTokenKey;
  static const _userKey = AppConstants.userDataKey;

  @override
  Future<void> cacheTokens(AuthTokensModel tokens) async {
    await _secureStorage.write(_accessTokenKey, tokens.token);
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
  Future<UserModel?> getLastUser() async {
    final userJson = await _secureStorage.read(_userKey);
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson));
  }
  
  @override
  Future<void> clearCache() async {
    await _secureStorage.deleteAll();
  }
}
