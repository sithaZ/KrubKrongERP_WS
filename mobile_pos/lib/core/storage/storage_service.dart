import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../errors/failures.dart';

/// Abstract secure storage interface
abstract class SecureStorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// Abstract shared preferences interface
abstract class SharedPreferencesService {
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> setBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> setInt(String key, int value);
  Future<int?> getInt(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

/// Implementation using flutter_secure_storage for sensitive data
class SecureStorageServiceImpl implements SecureStorageService {

  SecureStorageServiceImpl(this._secureStorage);
  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> write(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e, stackTrace) {
      throw CacheException('Failed to write secure data').toFailure(stackTrace: stackTrace);
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e, stackTrace) {
      throw CacheException('Failed to read secure data').toFailure(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e, stackTrace) {
      throw CacheException('Failed to delete secure data').toFailure(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e, stackTrace) {
      throw CacheException('Failed to clear secure data').toFailure(stackTrace: stackTrace);
    }
  }
}

/// Implementation using shared_preferences for non-sensitive data
class SharedPreferencesServiceImpl implements SharedPreferencesService {

  SharedPreferencesServiceImpl(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<void> setString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (e, stackTrace) {
      throw CacheException('Failed to save string').toFailure(stackTrace: stackTrace);
    }
  }

  @override
  Future<String?> getString(String key) async {
    try {
      return _prefs.getString(key);
    } catch (e, stackTrace) {
      throw CacheException('Failed to get string').toFailure(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setBool(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
    } catch (e, stackTrace) {
      throw CacheException('Failed to save bool').toFailure(stackTrace: stackTrace);
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    try {
      return _prefs.getBool(key);
    } catch (e, stackTrace) {
      throw CacheException('Failed to get bool').toFailure(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
    } catch (e, stackTrace) {
      throw CacheException('Failed to save int').toFailure(stackTrace: stackTrace);
    }
  }

  @override
  Future<int?> getInt(String key) async {
    try {
      return _prefs.getInt(key);
    } catch (e, stackTrace) {
      throw CacheException('Failed to get int').toFailure(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
    } catch (e, stackTrace) {
      throw CacheException('Failed to remove data').toFailure(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _prefs.clear();
    } catch (e, stackTrace) {
      throw CacheException('Failed to clear data').toFailure(stackTrace: stackTrace);
    }
  }
}