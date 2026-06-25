/// REST API endpoints organization
abstract class ApiConstants {
  ApiConstants._();

  // Auth Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  static const String getCurrentUserEndpoint = '/auth/me';
  static const String logoutEndpoint = '/auth/logout';

  // Product / Inventory Endpoints
  static const String productsEndpoint = '/products';
  static const String lowStockProductsEndpoint = '/products/low-stock';

  // Order / POS Endpoints
  static const String ordersEndpoint = '/orders';
  static const String orderPerformanceEndpoint = '/orders/performance/summary';
}
