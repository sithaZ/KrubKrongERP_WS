import 'package:equatable/equatable.dart';

/// Product entity
class Product extends Equatable {

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.sku,
    required this.price,
    this.costPrice,
    required this.stockQuantity,
    this.imageUrl,
    required this.categoryId,
    this.categoryName,
    this.isActive = true,
    this.createdAt,
  });
  final String id;
  final String name;
  final String? description;
  final String sku;
  final double price;
  final double? costPrice;
  final int stockQuantity;
  final String? imageUrl;
  final String categoryId;
  final String? categoryName;
  final bool isActive;
  final DateTime? createdAt;

  bool get isInStock => stockQuantity > 0;
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 10;

  @override
  List<Object?> get props => [
    id,
    name,
    sku,
    price,
    stockQuantity,
    categoryId,
    isActive,
  ];

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? sku,
    double? price,
    double? costPrice,
    int? stockQuantity,
    String? imageUrl,
    String? categoryId,
    String? categoryName,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Category entity
class Category extends Equatable {

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.isActive = true,
  });
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, parentId, isActive];
}

/// Cart item
class CartItem extends Equatable {

  CartItem({
    required this.product,
    this.quantity = 1,
  });
  final Product product;
  int quantity;

  double get total => product.price * quantity;

  @override
  List<Object?> get props => [product.id, quantity];
}

/// Order entity
class Order extends Equatable {

  const Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.status = OrderStatus.pending,
    this.customerId,
    this.customerName,
    required this.cashierId,
    required this.createdAt,
    this.notes,
  });
  final String id;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final OrderStatus status;
  final String? customerId;
  final String? customerName;
  final String cashierId;
  final DateTime createdAt;
  final String? notes;

  @override
  List<Object?> get props => [id, items, total, status, createdAt];
}

/// Order item
class OrderItem extends Equatable {

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.total,
  });
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double total;

  @override
  List<Object?> get props => [productId, quantity];
}

enum OrderStatus {
  pending,
  processing,
  completed,
  cancelled,
  refunded,
}
