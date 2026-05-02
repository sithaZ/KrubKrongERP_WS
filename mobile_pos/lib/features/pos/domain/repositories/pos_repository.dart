import 'package:fpdart/fpdart.dart' hide Order;
import '../../../../core/errors/failures.dart';
import '../entities/pos_entities.dart';

/// POS repository interface
abstract class PosRepository {
  // Product operations
  Future<Either<Failure, List<Product>>> getProducts({
    String? categoryId,
    String? search,
  });
  Future<Either<Failure, Product>> getProductById(String id);

  // Category operations
  Future<Either<Failure, List<Category>>> getCategories();

  // Order operations
  Future<Either<Failure, Order>> createOrder({
    required List<CartItem> items,
    String? customerId,
    String? notes,
  });
  Future<Either<Failure, List<Order>>> getOrders({
    DateTime? from,
    DateTime? to,
    OrderStatus? status,
  });
}
