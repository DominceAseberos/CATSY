import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ── Table imports ──────────────────────────────────────────────────────
import 'tables/staff_table.dart';
import 'tables/products_table.dart';
import 'tables/categories_table.dart';
import 'tables/addons_table.dart';
import 'tables/orders_table.dart';
import 'tables/order_items_table.dart';
import 'tables/order_item_addons_table.dart';
import 'tables/reservations_table.dart';
import 'tables/cafe_tables_table.dart';
import 'tables/customers_table.dart';
import 'tables/loyalty_stamps_table.dart';
import 'tables/inventory_table.dart';
import 'tables/transactions_table.dart';
import 'tables/receipts_table.dart';
import 'tables/rewards_table.dart';
import 'tables/sync_queue_table.dart';

// ── DAO imports ────────────────────────────────────────────────────────
import 'daos/auth_dao.dart';
import 'daos/product_dao.dart';
import 'daos/order_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/customer_dao.dart';
import 'daos/reservation_dao.dart';
import 'daos/table_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/reward_dao.dart';
import 'daos/receipt_dao.dart';

part 'app_database.g.dart';

/// Riverpod provider for the Drift database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

@DriftDatabase(
  tables: [
    StaffTable,
    ProductsTable,
    CategoriesTable,
    AddonsTable,
    OrdersTable,
    OrderItemsTable,
    OrderItemAddonsTable,
    ReservationsTable,
    CafeTablesTable,
    CustomersTable,
    LoyaltyStampsTable,
    InventoryTable,
    TransactionsTable,
    ReceiptsTable,
    RewardsTable,
    SyncQueueTable,
  ],
  daos: [
    AuthDao,
    ProductDao,
    OrderDao,
    InventoryDao,
    CustomerDao,
    ReservationDao,
    TableDao,
    TransactionDao,
    SyncQueueDao,
    RewardDao,
    ReceiptDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Named constructor for unit tests — accepts an in-memory executor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Migration from v1 to v2: Add receipt_number column to receipts table
        await m.addColumn(receiptsTable, receiptsTable.receiptNumber);
      }
      if (from < 3) {
        // Migration v2→v3 (Phase 9): Add claim columns to rewards_table.
        // Using customStatement for nullable / default columns avoids Drift
        // type-mismatch issues before code regeneration.
        await customStatement(
          'ALTER TABLE rewards_table ADD COLUMN code TEXT;',
        );
        await customStatement(
          'ALTER TABLE rewards_table ADD COLUMN customer_id TEXT;',
        );
        await customStatement(
          'ALTER TABLE rewards_table ADD COLUMN is_claimed INTEGER NOT NULL DEFAULT 0;',
        );
        await customStatement(
          'ALTER TABLE rewards_table ADD COLUMN claimed_by_staff_id TEXT;',
        );
        await customStatement(
          'ALTER TABLE rewards_table ADD COLUMN claimed_at INTEGER;',
        );
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'catsy_pos.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
