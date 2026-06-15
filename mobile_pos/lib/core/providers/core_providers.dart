import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../network/http_client.dart';
import '../network/network_info.dart';
import '../storage/storage_service.dart';

// ==================== Core Services ====================

/// Secure storage provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageServiceImpl(const FlutterSecureStorage());
});

final sharedPreferencesInstanceProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesInstanceProvider must be overridden in main()',
  );
});

final sharedPreferencesServiceProvider = Provider<SharedPreferencesService>((ref) {
  return SharedPreferencesServiceImpl(ref.watch(sharedPreferencesInstanceProvider));
});

/// Shared preferences provider (needs async initialization)
final sharedPreferencesProvider =
    FutureProvider<SharedPreferencesService>((ref) async {
  return ref.watch(sharedPreferencesServiceProvider);
});

/// Network info provider
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(InternetConnectionChecker());
});

/// HTTP client provider
final httpClientProvider = Provider<HttpClientConfig>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final config = HttpClientConfig(secureStorage);
  config.initialize();
  return config;
});

/// HTTP client instance provider (Dio)
final httpClientInstanceProvider = Provider<Dio>((ref) {
  return ref.watch(httpClientProvider).client;
});
