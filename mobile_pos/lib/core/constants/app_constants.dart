/// App-wide constants
abstract class AppConstants {
  AppConstants._();

  // API Configuration
  static const String restApiEndpoint = 'REST_API_ENDPOINT';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String companyIdKey = 'company_id';
  static const String userDataKey = 'user_data';
  static const String themeModeKey = 'theme_mode';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // App Info
  static const String appName = 'ERP Mobile';
  static const String appVersion = '1.0.0';
}
