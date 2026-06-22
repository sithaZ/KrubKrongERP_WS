import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/entities/pos_entities.dart';

class PosApiService {
  PosApiService(this._client);

  final Dio _client;

  Future<List<Product>> fetchProducts({String? search}) async {
    return _fetchProducts(
      search: search,
      activeOnly: true,
      inStockOnly: true,
    );
  }

  Future<List<Product>> fetchInventoryProducts({String? search}) async {
    return _fetchProducts(
      search: search,
      activeOnly: true,
      inStockOnly: false,
    );
  }

  Future<List<Product>> _fetchProducts({
    String? search,
    required bool activeOnly,
    required bool inStockOnly,
  }) async {
    final response = await _client.get(
      ApiConstants.productsEndpoint,
      queryParameters: {
        'activeOnly': activeOnly,
        'inStockOnly': inStockOnly,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final data = response.data;
    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => _mapProduct(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Product> createProduct({
    required String name,
    required double price,
    required int stockQuantity,
    String? imageUrl,
  }) async {
    final response = await _client.post(
      ApiConstants.productsEndpoint,
      data: {
        'name': name.trim(),
        'price': price,
        'stockQuantity': stockQuantity,
        'imageUrl': imageUrl?.trim() ?? '',
      },
    );

    return _mapProduct(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Product> updateProduct({
    required String productId,
    required String name,
    required double price,
    required int stockQuantity,
    String? imageUrl,
  }) async {
    final response = await _client.patch(
      '${ApiConstants.productsEndpoint}/$productId',
      data: {
        'name': name.trim(),
        'price': price,
        'stockQuantity': stockQuantity,
        'imageUrl': imageUrl?.trim() ?? '',
      },
    );

    return _mapProduct(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Product> stopSellingProduct(String productId) async {
    final response = await _client.patch(
      '${ApiConstants.productsEndpoint}/$productId',
      data: {
        'isActive': false,
      },
    );

    return _mapProduct(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Product> adjustProductStock({
    required String productId,
    required int quantityChange,
    String note = '',
  }) async {
    final response = await _client.patch(
      '${ApiConstants.productsEndpoint}/$productId/stock',
      data: {
        'type': quantityChange >= 0 ? 'RESTOCK' : 'ADJUSTMENT',
        'quantityChange': quantityChange,
        'note': note,
      },
    );

    return _mapProduct(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<Product>> fetchLowStockProducts() async {
    final response = await _client.get(ApiConstants.lowStockProductsEndpoint);
    final data = response.data;
    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => _mapProduct(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Order> createOrder({
    required List<CartItem> items,
    String? notes,
    String paymentMethod = 'cash',
  }) async {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    const tax = 0.0;

    final response = await _client.post(
      ApiConstants.ordersEndpoint,
      data: {
        'items': items
            .map(
              (item) => {
                'productId': item.product.id,
                'quantity': item.quantity,
              },
            )
            .toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': subtotal + tax,
        'paymentMethod': paymentMethod,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    return _mapOrder(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<Order>> fetchOrders() async {
    final response = await _client.get(ApiConstants.ordersEndpoint);
    final data = response.data;
    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => _mapOrder(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Map<String, dynamic>> fetchReceiptPerformance() async {
    final response = await _client.get(ApiConstants.orderPerformanceEndpoint);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const {};
  }

  Product _mapProduct(Map<String, dynamic> json) {
    final priceValue = json['price'] ?? 0;
    final costPriceValue = json['costPrice'];
    final stockValue = json['stockQuantity'] ?? 0;

    return Product(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      sku: json['sku']?.toString() ?? '',
      price: (priceValue as num).toDouble(),
      costPrice: costPriceValue is num ? costPriceValue.toDouble() : null,
      stockQuantity: (stockValue as num).toInt(),
      imageUrl: json['imageUrl']?.toString(),
      categoryId: json['categoryId']?.toString() ?? 'general',
      categoryName: json['categoryName']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  Order _mapOrder(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final cashierRaw = json['cashierId'];
    final cashierId = cashierRaw is Map
        ? cashierRaw['_id']?.toString() ?? ''
        : cashierRaw?.toString() ?? '';

    return Order(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      items: itemsRaw is List
          ? itemsRaw
              .whereType<Map>()
              .map(
                (item) => OrderItem(
                  productId: item['productId']?.toString() ?? '',
                  productName: item['productName']?.toString() ?? '',
                  unitPrice: ((item['unitPrice'] ?? 0) as num).toDouble(),
                  quantity: ((item['quantity'] ?? 0) as num).toInt(),
                  total: ((item['total'] ?? 0) as num).toDouble(),
                ),
              )
              .toList()
          : const [],
      subtotal: ((json['subtotal'] ?? 0) as num).toDouble(),
      discount: ((json['discount'] ?? 0) as num).toDouble(),
      tax: ((json['tax'] ?? 0) as num).toDouble(),
      total: ((json['total'] ?? 0) as num).toDouble(),
      status: _mapOrderStatus(json['status']?.toString()),
      customerId: json['customerId']?.toString(),
      customerName: json['customerName']?.toString(),
      cashierId: cashierId,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      receiptNumber: json['receiptNumber']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  OrderStatus _mapOrderStatus(String? rawStatus) {
    switch ((rawStatus ?? '').toLowerCase()) {
      case 'completed':
        return OrderStatus.completed;
      case 'processing':
        return OrderStatus.processing;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }
}

/// Cart state
class CartState {

  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });
  final List<CartItem> items;
  final bool isLoading;
  final String? error;

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get tax => 0;
  double get total => subtotal + tax;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Cart notifier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addToCart(Product product) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      final nextQuantity = state.items[existingIndex].quantity + 1;
      if (nextQuantity > product.stockQuantity) {
        state = state.copyWith(error: 'Not enough stock for ${product.name}');
        return;
      }

      final updatedItems = [...state.items];
      updatedItems[existingIndex] = CartItem(
        product: product,
        quantity: nextQuantity,
      );
      state = state.copyWith(items: updatedItems, error: null);
    } else {
      if (!product.isInStock) {
        state = state.copyWith(error: '${product.name} is out of stock');
        return;
      }

      state = state.copyWith(
        items: [...state.items, CartItem(product: product)],
        error: null,
      );
    }
  }

  void removeFromCart(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final item = state.items.cast<CartItem?>().firstWhere(
          (entry) => entry?.product.id == productId,
          orElse: () => null,
        );

    if (item != null && quantity > item.product.stockQuantity) {
      state = state.copyWith(
        error: 'Not enough stock for ${item.product.name}',
      );
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.product.id == productId) {
        return CartItem(product: item.product, quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems, error: null);
  }

  void clearCart() {
    state = const CartState();
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

final posApiServiceProvider = Provider<PosApiService>((ref) {
  return PosApiService(ref.watch(httpClientInstanceProvider));
});

final posSearchProvider = StateProvider<String>((ref) => '');

/// POS products provider
final posProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(posApiServiceProvider).fetchProducts(
        search: ref.watch(posSearchProvider),
      );
});

final inventoryProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(posApiServiceProvider).fetchInventoryProducts();
});

/// POS categories provider (mock for scaffold)
final posCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  // This would fetch from GraphQL in production
  return [];
});

final posOrdersProvider = FutureProvider<List<Order>>((ref) async {
  return ref.watch(posApiServiceProvider).fetchOrders();
});

final receiptPerformanceProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return ref.watch(posApiServiceProvider).fetchReceiptPerformance();
});

final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(posApiServiceProvider).fetchLowStockProducts();
});
