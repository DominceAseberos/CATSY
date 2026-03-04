import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/cafe_tables_table.dart';

part 'table_dao.g.dart';

@DriftAccessor(tables: [CafeTablesTable])
class TableDao extends DatabaseAccessor<AppDatabase> with _$TableDaoMixin {
  TableDao(super.db);

  // ── Watch ────────────────────────────────────────────────────────────
  Stream<List<CafeTablesTableData>> watchAllTables() =>
      select(cafeTablesTable).watch();

  // ── Read ─────────────────────────────────────────────────────────────
  Future<List<CafeTablesTableData>> getAllTables() =>
      select(cafeTablesTable).get();

  Future<CafeTablesTableData?> getTableById(String id) => (select(
    cafeTablesTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  // ── Write ───────────────────────────────────────────────────────────
  Future<void> updateTableStatus(String id, String status) =>
      (update(cafeTablesTable)..where((t) => t.id.equals(id))).write(
        CafeTablesTableCompanion(status: Value(status)),
      );

  Future<void> assignOrder(String tableId, String orderId) =>
      (update(cafeTablesTable)..where((t) => t.id.equals(tableId))).write(
        CafeTablesTableCompanion(
          status: const Value('occupied'),
          currentOrderId: Value(orderId),
        ),
      );

  Future<void> clearTable(String tableId) =>
      (update(cafeTablesTable)..where((t) => t.id.equals(tableId))).write(
        const CafeTablesTableCompanion(
          status: Value('available'),
          currentOrderId: Value.absent(),
        ),
      );

  Future<void> upsertTable(CafeTablesTableCompanion table) =>
      into(cafeTablesTable).insertOnConflictUpdate(table);

  Future<void> deleteTable(String id) =>
      (delete(cafeTablesTable)..where((t) => t.id.equals(id))).go();
}
