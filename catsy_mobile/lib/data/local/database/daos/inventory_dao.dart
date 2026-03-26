import 'package:drift/drift.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/tables/inventory_table.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [InventoryTable])
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  // ── Watch ────────────────────────────────────────────────────────────
  Stream<List<InventoryTableData>> watchAllInventory() =>
      select(inventoryTable).watch();

  Stream<int> watchLowStockCount() {
    final query = selectOnly(inventoryTable)
      ..addColumns([inventoryTable.id.count()])
      ..where(
        inventoryTable.currentStock.isSmallerOrEqual(inventoryTable.minStock),
      );
    return query
        .map((row) => row.read(inventoryTable.id.count()) ?? 0)
        .watchSingle();
  }

  // ── Read ─────────────────────────────────────────────────────────────
  Future<InventoryTableData?> getInventoryForProduct(String productId) =>
      (select(
        inventoryTable,
      )..where((t) => t.productId.equals(productId))).getSingleOrNull();

  Future<int> getStockForProduct(String productId) async {
    final item = await getInventoryForProduct(productId);
    return item?.currentStock ?? 0;
  }

  Future<List<InventoryTableData>> getLowStockItems() => (select(
    inventoryTable,
  )..where((t) => t.currentStock.isSmallerOrEqual(t.minStock))).get();

  // ── Write ───────────────────────────────────────────────────────────
  Future<void> deductStock(String productId, int quantity) async {
    final item = await getInventoryForProduct(productId);
    if (item == null) return;
    final newStock = (item.currentStock - quantity).clamp(0, 999999);
    await (update(inventoryTable)..where((t) => t.productId.equals(productId)))
        .write(InventoryTableCompanion(currentStock: Value(newStock)));
  }

  Future<void> upsertInventoryItem(InventoryTableCompanion item) =>
      into(inventoryTable).insertOnConflictUpdate(item);
}
