import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ── Table imports ──────────────────────────────────────────────────────
import 'package:catsy_pos/data/local/database/tables/staff_table.dart';
import 'package:catsy_pos/data/local/database/tables/products_table.dart';
import 'package:catsy_pos/data/local/database/tables/categories_table.dart';
import 'package:catsy_pos/data/local/database/tables/addons_table.dart';
import 'package:catsy_pos/data/local/database/tables/orders_table.dart';
import 'package:catsy_pos/data/local/database/tables/order_items_table.dart';
import 'package:catsy_pos/data/local/database/tables/order_item_addons_table.dart';
import 'package:catsy_pos/data/local/database/tables/reservations_table.dart';
import 'package:catsy_pos/data/local/database/tables/cafe_tables_table.dart';
import 'package:catsy_pos/data/local/database/tables/customers_table.dart';
import 'package:catsy_pos/data/local/database/tables/loyalty_stamps_table.dart';
import 'package:catsy_pos/data/local/database/tables/inventory_table.dart';
import 'package:catsy_pos/data/local/database/tables/transactions_table.dart';
import 'package:catsy_pos/data/local/database/tables/receipts_table.dart';
import 'package:catsy_pos/data/local/database/tables/rewards_table.dart';
import 'package:catsy_pos/data/local/database/tables/sync_queue_table.dart';
import 'package:catsy_pos/data/local/database/tables/sync_conflict_log_table.dart';

// ── DAO imports ────────────────────────────────────────────────────────
import 'package:catsy_pos/data/local/database/daos/auth_dao.dart';
import 'package:catsy_pos/data/local/database/daos/product_dao.dart';
import 'package:catsy_pos/data/local/database/daos/order_dao.dart';
import 'package:catsy_pos/data/local/database/daos/inventory_dao.dart';
import 'package:catsy_pos/data/local/database/daos/customer_dao.dart';
import 'package:catsy_pos/data/local/database/daos/reservation_dao.dart';
import 'package:catsy_pos/data/local/database/daos/table_dao.dart';
import 'package:catsy_pos/data/local/database/daos/transaction_dao.dart';
import 'package:catsy_pos/data/local/database/daos/sync_queue_dao.dart';
import 'package:catsy_pos/data/local/database/daos/reward_dao.dart';
import 'package:catsy_pos/data/local/database/daos/receipt_dao.dart';

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
    SyncConflictLogTable,
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
  int get schemaVersion => 4;

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
      if (from < 4) {
        // Migration v3→v4 (Phase 14): Add priority to sync_queue_table,
        // create sync_conflict_log_table.
        await customStatement(
          'ALTER TABLE sync_queue_table ADD COLUMN priority INTEGER NOT NULL DEFAULT 0;',
        );
        await customStatement('''
          CREATE TABLE IF NOT EXISTS sync_conflict_log_table (
            id TEXT NOT NULL PRIMARY KEY,
            target_table TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            local_json TEXT NOT NULL,
            remote_json TEXT NOT NULL,
            winner TEXT NOT NULL,
            resolved_at INTEGER NOT NULL
          );
          ''');
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
