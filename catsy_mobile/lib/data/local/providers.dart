import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../data/local/database/app_database.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/reservation_repository_impl.dart';
import '../../data/repositories/table_repository_impl.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../../domain/repositories/table_repository.dart';

import '../../domain/repositories/customer_repository.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/repositories/reward_repository.dart';
import '../../data/repositories/reward_repository_impl.dart';
import '../../core/network/connectivity_service.dart';

// ── Database Provider ────────────────────────────────────────────────────────
// Re-exporting from app_database.dart for convenience, or we can just rely on the import.
// For clarity in this file, we refer to the one defined in app_database.dart.

// ── DAO Providers ────────────────────────────────────────────────────────────
final productDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).productDao,
);
final orderDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).orderDao,
);
final inventoryDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).inventoryDao,
);
final customerDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).customerDao,
);
final reservationDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).reservationDao,
);
final tableDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).tableDao,
);
final transactionDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).transactionDao,
);
final syncQueueDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).syncQueueDao,
);

// ── Stream Providers (Reactive Data) ─────────────────────────────────────────

/// Watches all active orders (status != completed/cancelled)
final activeOrdersProvider = StreamProvider((ref) {
  return ref.watch(orderDaoProvider).watchActiveOrders();
});

/// Watches the count of pending reservations
final pendingReservationsCountProvider = StreamProvider((ref) {
  return ref.watch(reservationDaoProvider).watchPendingCount();
});

/// Watches the count of low stock items
final lowStockItemsCountProvider = StreamProvider((ref) {
  return ref.watch(inventoryDaoProvider).watchLowStockCount();
});

/// Watches today's transactions and calculates total sales
final todaysSalesTotalProvider = StreamProvider<double>((ref) {
  return ref.watch(transactionDaoProvider).watchTodayTransactions().map((
    transactions,
  ) {
    return transactions.fold<double>(0, (sum, t) => sum + t.amount);
  });
});

/// Watches pending sync queue count
final syncPendingCountProvider = StreamProvider((ref) {
  return ref.watch(syncQueueDaoProvider).watchPendingCount();
});

/// Watches all products
final allProductsProvider = StreamProvider((ref) {
  return ref.watch(productDaoProvider).watchAllProducts();
});

/// Watches all tables
final allTablesProvider = StreamProvider((ref) {
  return ref.watch(tableDaoProvider).watchAllTables();
});

// ── Auth Providers ──────────────────────────────────────────────────────────

final authDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).authDao,
);


// ── Table Providers ─────────────────────────────────────────────────────────

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return TableRepositoryImpl(
    tableDao: ref.watch(tableDaoProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});

// ── Reservation Providers ───────────────────────────────────────────────────

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepositoryImpl(
    reservationDao: ref.watch(reservationDaoProvider),
    tableDao: ref.watch(tableDaoProvider),
  );
});

// ── Product Providers ───────────────────────────────────────────────────────

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(productDao: ref.watch(productDaoProvider));
});

// ── Inventory Providers ─────────────────────────────────────────────────────

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(inventoryDao: ref.watch(inventoryDaoProvider));
});

// ── Receipt DAO Provider ─────────────────────────────────────────────────────

final receiptDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).receiptDao,
);

// ── Order Provider ──────────────────────────────────────────────────────────

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(
    ref.watch(orderDaoProvider),
    ref.watch(inventoryDaoProvider),
    ref.watch(transactionDaoProvider),
    ref.watch(receiptDaoProvider),
    ref.watch(appDatabaseProvider),
  );
});

// ── Customer Provider ───────────────────────────────────────────────────────

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl(customerDao: ref.watch(customerDaoProvider));
});

// ── Reward Providers ─────────────────────────────────────────────────────────

final rewardDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).rewardDao,
);

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return RewardRepositoryImpl(
    rewardDao: ref.watch(rewardDaoProvider),
    customerDao: ref.watch(customerDaoProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});
