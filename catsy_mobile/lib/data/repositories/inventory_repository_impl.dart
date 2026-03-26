import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:catsy_pos/core/error/failures.dart';
import 'package:catsy_pos/domain/entities/inventory_item.dart';
import 'package:catsy_pos/domain/repositories/inventory_repository.dart';
import 'package:catsy_pos/data/local/database/daos/inventory_dao.dart';
import 'package:catsy_pos/data/local/database/app_database.dart'; // For generated data classes

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryDao _inventoryDao;

  InventoryRepositoryImpl({required InventoryDao inventoryDao})
    : _inventoryDao = inventoryDao;

  @override
  Stream<List<InventoryItem>> watchInventory() {
    return _inventoryDao.watchAllInventory().map(
      (rows) => rows.map(_mapInventoryItem).toList(),
    );
  }

  @override
  Stream<int> watchLowStockCount() {
    return _inventoryDao.watchLowStockCount();
  }

  @override
  Future<Either<Failure, List<InventoryItem>>> getLowStockItems() async {
    try {
      final rows = await _inventoryDao.getLowStockItems();
      return Right(rows.map(_mapInventoryItem).toList());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get low stock items: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getStockForProduct(String productId) async {
    try {
      final stock = await _inventoryDao.getStockForProduct(productId);
      return Right(stock);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get stock: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deductStock(
    String productId,
    int quantity,
  ) async {
    try {
      await _inventoryDao.deductStock(productId, quantity);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to deduct stock: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateStock(
    String productId,
    int newStock,
  ) async {
    try {
      // NOTE: InventoryDao doesn't have a direct 'updateStock' method exposed as simple 'setStock'.
      // But it has `upsertInventoryItem`. We need to fetch the item first to preserve other fields?
      // Or we can assume we only update stock.
      // Let's implement it by updating only the stock column if item exists.
      // Using upsert with only relevant data might overwrite others if not careful.
      // Best approach: Add `updateStock` to DAO or use a query here.
      // Since we are in the repository, we can use the DAO's existing methods.
      // `deductStock` logic in DAO uses an update query. We can replicate logic or create a method in DAO.
      // For now, let's use `upsertInventoryItem` but we need the full object.

      final currentItem = await _inventoryDao.getInventoryForProduct(productId);
      if (currentItem == null) {
        // If not exists, create with defaults? or error?
        // Let's create it.
        // Problem: We need productName, etc. which are not passed here.
        // This implies updateStock assumes existence.
        return Left(
          CacheFailure(
            message: 'Inventory item not found for product $productId',
          ),
        );
      }

      await _inventoryDao.upsertInventoryItem(
        currentItem
            .toCompanion(true)
            .copyWith(
              currentStock: Value(newStock),
              lastRestocked: Value(DateTime.now()),
            ),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to update stock: $e'));
    }
  }

  InventoryItem _mapInventoryItem(InventoryTableData i) {
    return InventoryItem(
      id: i.id,
      productId: i.productId,
      productName: i.productName,
      currentStock: i.currentStock,
      minStock: i.minStock,
      unit: i.unit,
      lastRestocked: i.lastRestocked,
    );
  }
}
