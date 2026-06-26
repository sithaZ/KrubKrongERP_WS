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

  Future<List<Product>> fetchAllProducts({String? search}) async {
    return _fetchProducts(
      search: search,
      activeOnly: false,
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
    String? sku,
    String? barcode,
    String? description,
    double? costPrice,
    String? categoryId,
    String? categoryName,
    int? reorderLevel,
    bool? isActive,
  }) async {
    final response = await _client.post(
      ApiConstants.productsEndpoint,
      data: {
        'name': name.trim(),
        'price': price,
        'stockQuantity': stockQuantity,
        if (imageUrl != null) 'imageUrl': imageUrl.trim(),
        if (sku != null && sku.trim().isNotEmpty) 'sku': sku.trim(),
        if (barcode != null && barcode.trim().isNotEmpty) 'barcode': barcode.trim(),
        if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
        if (costPrice != null) 'costPrice': costPrice,
        if (categoryId != null && categoryId.trim().isNotEmpty) 'categoryId': categoryId.trim(),
        if (categoryName != null && categoryName.trim().isNotEmpty) 'categoryName': categoryName.trim(),
        if (reorderLevel != null) 'reorderLevel': reorderLevel,
        if (isActive != null) 'isActive': isActive,
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
    String? sku,
    String? barcode,
    String? description,
    double? costPrice,
    String? categoryId,
    String? categoryName,
    int? reorderLevel,
    bool? isActive,
  }) async {
    final response = await _client.patch(
      '${ApiConstants.productsEndpoint}/$productId',
      data: {
        'name': name.trim(),
        'price': price,
        'stockQuantity': stockQuantity,
        if (imageUrl != null) 'imageUrl': imageUrl.trim(),
        if (sku != null && sku.trim().isNotEmpty) 'sku': sku.trim(),
        if (barcode != null && barcode.trim().isNotEmpty) 'barcode': barcode.trim(),
        if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
        if (costPrice != null) 'costPrice': costPrice,
        if (categoryId != null && categoryId.trim().isNotEmpty) 'categoryId': categoryId.trim(),
        if (categoryName != null && categoryName.trim().isNotEmpty) 'categoryName': categoryName.trim(),
        if (reorderLevel != null) 'reorderLevel': reorderLevel,
        if (isActive != null) 'isActive': isActive,
      },
    );

    return _mapProduct(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Product> setProductStatus(String productId, bool isActive) async {
    final response = await _client.patch(
      '${ApiConstants.productsEndpoint}/$productId',
      data: {
        'isActive': isActive,
      },
    );

    return _mapProduct(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Product> stopSellingProduct(String productId) async {
    return setProductStatus(productId, false);
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

/// Selected table provider
final selectedTableProvider = StateProvider<String>((ref) => 'Table 1');

/// List of tables provider
final tablesListProvider = StateProvider<List<String>>((ref) => [
  'Table 1',
  'Table 2',
  'Table 3',
  'Table 4',
  'Table 5',
  'Table 6',
  'Table 7',
  'Table 8',
  'Table 9',
  'Table 10',
  'Take Away 1',
  'Take Away 2',
  'Take Away 3',
  'Take Away 4',
  'Take Away 5',
]);

/// Table carts notifier
class TableCartsNotifier extends StateNotifier<Map<String, CartState>> {
  TableCartsNotifier() : super(const {});

  void addToCart(String tableId, Product product) {
    final currentCart = state[tableId] ?? const CartState();
    final existingIndex = currentCart.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    CartState updatedCart;
    if (existingIndex >= 0) {
      final nextQuantity = currentCart.items[existingIndex].quantity + 1;
      if (nextQuantity > product.stockQuantity) {
        updatedCart = currentCart.copyWith(
          error: 'Not enough stock for ${product.name}',
        );
      } else {
        final updatedItems = [...currentCart.items];
        updatedItems[existingIndex] = CartItem(
          product: product,
          quantity: nextQuantity,
        );
        updatedCart = currentCart.copyWith(items: updatedItems, error: null);
      }
    } else {
      if (!product.isInStock) {
        updatedCart = currentCart.copyWith(
          error: '${product.name} is out of stock',
        );
      } else {
        updatedCart = currentCart.copyWith(
          items: [...currentCart.items, CartItem(product: product)],
          error: null,
        );
      }
    }

    state = {
      ...state,
      tableId: updatedCart,
    };
  }

  void removeFromCart(String tableId, String productId) {
    final currentCart = state[tableId] ?? const CartState();
    final updatedCart = currentCart.copyWith(
      items: currentCart.items.where((item) => item.product.id != productId).toList(),
    );
    state = {
      ...state,
      tableId: updatedCart,
    };
  }

  void updateQuantity(String tableId, String productId, int quantity) {
    final currentCart = state[tableId] ?? const CartState();
    if (quantity <= 0) {
      removeFromCart(tableId, productId);
      return;
    }

    final item = currentCart.items.cast<CartItem?>().firstWhere(
          (entry) => entry?.product.id == productId,
          orElse: () => null,
        );

    CartState updatedCart;
    if (item != null && quantity > item.product.stockQuantity) {
      updatedCart = currentCart.copyWith(
        error: 'Not enough stock for ${item.product.name}',
      );
    } else {
      final updatedItems = currentCart.items.map((item) {
        if (item.product.id == productId) {
          return CartItem(product: item.product, quantity: quantity);
        }
        return item;
      }).toList();
      updatedCart = currentCart.copyWith(items: updatedItems, error: null);
    }

    state = {
      ...state,
      tableId: updatedCart,
    };
  }

  void clearCart(String tableId) {
    state = {
      ...state,
      tableId: const CartState(),
    };
  }

  void clearError(String tableId) {
    final currentCart = state[tableId] ?? const CartState();
    if (currentCart.error != null) {
      state = {
        ...state,
        tableId: currentCart.copyWith(error: null),
      };
    }
  }
}

/// Table carts provider
final tableCartsProvider = StateNotifierProvider<TableCartsNotifier, Map<String, CartState>>((ref) {
  return TableCartsNotifier();
});

/// Cart notifier that keeps in sync with tableCartsProvider and selectedTableProvider
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this.ref) : super(const CartState()) {
    _sync();
  }

  final Ref ref;

  void _sync() {
    ref.listen<Map<String, CartState>>(tableCartsProvider, (prev, next) {
      final selectedTable = ref.read(selectedTableProvider);
      state = next[selectedTable] ?? const CartState();
    });

    ref.listen<String>(selectedTableProvider, (prev, next) {
      final allCarts = ref.read(tableCartsProvider);
      state = allCarts[next] ?? const CartState();
    });

    // Set initial state
    final selectedTable = ref.read(selectedTableProvider);
    final allCarts = ref.read(tableCartsProvider);
    state = allCarts[selectedTable] ?? const CartState();
  }

  void addToCart(Product product) {
    final selectedTable = ref.read(selectedTableProvider);
    ref.read(tableCartsProvider.notifier).addToCart(selectedTable, product);
  }

  void removeFromCart(String productId) {
    final selectedTable = ref.read(selectedTableProvider);
    ref.read(tableCartsProvider.notifier).removeFromCart(selectedTable, productId);
  }

  void updateQuantity(String productId, int quantity) {
    final selectedTable = ref.read(selectedTableProvider);
    ref.read(tableCartsProvider.notifier).updateQuantity(selectedTable, productId, quantity);
  }

  void clearCart() {
    final selectedTable = ref.read(selectedTableProvider);
    ref.read(tableCartsProvider.notifier).clearCart(selectedTable);
  }

  void clearError() {
    final selectedTable = ref.read(selectedTableProvider);
    ref.read(tableCartsProvider.notifier).clearError(selectedTable);
  }
}

/// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
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

final productSearchProvider = StateProvider<String>((ref) => '');

final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(posApiServiceProvider).fetchAllProducts(
        search: ref.watch(productSearchProvider),
      );
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
