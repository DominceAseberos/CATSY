import 'package:dartz/dartz.dart';
import 'package:catsy_pos/core/error/failures.dart';
import 'package:catsy_pos/domain/entities/inventory_item.dart';

abstract class InventoryRepository {
  /// Watch all inventory items (stream).
  Stream<List<InventoryItem>> watchInventory();

  /// Watch count of low stock items (stream).
  Stream<int> watchLowStockCount();

  /// Get all low stock items.
  Future<Either<Failure, List<InventoryItem>>> getLowStockItems();

  /// Get current stock for a product.
  Future<Either<Failure, int>> getStockForProduct(String productId);

  /// Deduct stock for a product (local).
  Future<Either<Failure, void>> deductStock(String productId, int quantity);

  /// Manually update stock (e.g. restock).
  Future<Either<Failure, void>> updateStock(String productId, int newStock);

  // Future<Either<Failure, void>> syncInventory(); // Phase 7
}
