import 'package:equatable/equatable.dart';

/// Product entity for product management
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
    this.updatedAt,
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
  final DateTime? updatedAt;

  bool get isInStock => stockQuantity > 0;
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 10;

  double? get profitMargin {
    if (costPrice == null || costPrice == 0) return null;
    return ((price - costPrice!) / price) * 100;
  }

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
    DateTime? updatedAt,
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
      updatedAt: updatedAt ?? this.updatedAt,
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
    this.createdAt,
  });
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final bool isActive;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, name, parentId, isActive];

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? parentId,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
