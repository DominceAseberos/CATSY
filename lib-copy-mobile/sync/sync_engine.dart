import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/connectivity_service.dart';
import '../core/utils/logger.dart';
import '../data/local/database/app_database.dart';
import '../data/local/secure_storage/secure_storage_service.dart';
import '../data/remote/sources/customer_remote_source.dart';
import '../data/remote/sources/inventory_remote_source.dart';
import '../data/remote/sources/order_remote_source.dart';
import '../data/remote/sources/product_remote_source.dart';
import '../data/remote/sources/reservation_remote_source.dart';
import '../data/remote/sources/reward_remote_source.dart';
import '../data/remote/sources/table_remote_source.dart';
import 'sync_queue_manager.dart';
import 'sync_providers.dart';

/// Orchestrator that watches connectivity and periodically runs the sync queue.
///
/// When the device comes back online:
/// 1. **Push** — drains the local mutation queue via [SyncQueueManager]
/// 2. **Pull** — fetches incremental data from the API Bridge
class SyncEngine {
  final Ref _ref;
  Timer? _periodicTimer;
  StreamSubscription<bool>? _connectivitySub;

  SyncEngine(this._ref);

  // ── Lifecycle ──────────────────────────────────────────────────────────

  void start() {
    AppLogger.i('[SyncEngine] Starting…');
    _connectivitySub = ConnectivityService().onConnectivityChanged.listen((
      isOnline,
    ) {
      if (isOnline) {
        AppLogger.i('[SyncEngine] Back online → running sync');
        _syncAll();
      }
    });
    _periodicTimer = Timer.periodic(AppConstants.syncInterval, (_) {
      _syncAll();
    });
  }

  void stop() {
    AppLogger.i('[SyncEngine] Stopping…');
    _periodicTimer?.cancel();
    _connectivitySub?.cancel();
  }

  // ── Core ───────────────────────────────────────────────────────────────

  Future<void> _syncAll() async {
    final isOnline = await ConnectivityService().isConnected;
    if (!isOnline) return;

    // Trigger sync state
    _ref.read(isSyncingProvider.notifier).setSyncing(true);

    try {
      AppLogger.d('[SyncEngine] Running full sync…');
      await _pushPendingActions();
      await _pullFreshData();
    } finally {
      _ref.read(isSyncingProvider.notifier).setSyncing(false);
    }
  }

  Future<void> _pushPendingActions() async {
    try {
      final db = _ref.read(appDatabaseProvider);
      final api = _ref.read(apiClientProvider);
      await SyncQueueManager(dao: db.syncQueueDao, api: api).processQueue();
    } catch (e) {
      AppLogger.e('[SyncEngine] Push failed: $e');
    }
  }

  Future<void> _pullFreshData() async {
    try {
      final storage = _ref.read(secureStorageServiceProvider);
      final lastSync = await storage.getLastSyncTimestamp();
      final since = lastSync ?? DateTime.fromMillisecondsSinceEpoch(0);
      final api = _ref.read(apiClientProvider);
      final db = _ref.read(appDatabaseProvider);

      await Future.wait([
        _pullOrders(api, db, since),
        _pullProducts(api, db, since),
        _pullCategories(api, db, since),
        _pullCustomers(api, db, since),
        _pullReservations(api, db, since),
        _pullTables(api, db, since),
        _pullInventory(api, db, since),
        _pullRewards(api, db, since),
      ]);

      await storage.saveLastSyncTimestamp(DateTime.now());
      AppLogger.i('[SyncEngine] Pull complete');
    } catch (e) {
      AppLogger.e('[SyncEngine] Pull failed: $e');
    }
  }

  // ── Per-resource pull helpers ──────────────────────────────────────────

  Future<void> _pullOrders(
    ApiClient api,
    AppDatabase db,
    DateTime since,
  ) async {
    try {
      final dtos = await OrderRemoteSource(api).fetchOrdersSince(since);
      await db.transaction(() async {
        for (final dto in dtos) {
          await db
              .into(db.ordersTable)
              .insertOnConflictUpdate(
                OrdersTableCompanion(
                  id: Value(dto.id),
                  tableId: Value(dto.tableId),
                  staffId: Value(dto.staffId),
                  customerId: Value(dto.customerId),
                  orderType: Value(dto.orderType),
                  status: Value(dto.status),
                  paymentStatus: Value(dto.paymentStatus),
                  paymentMethod: Value(dto.paymentMethod),
                  subtotal: Value(dto.subtotal),
                  tax: Value(dto.tax),
                  discount: Value(dto.discount),
                  total: Value(dto.total),
                  notes: Value(dto.notes),
                  createdAt: Value(
                    DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
                  ),
                  updatedAt: Value(
                    DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
                  ),
                ),
              );
        }
      });
    } catch (e) {
      AppLogger.e('[SyncEngine] pullOrders: $e');
    }
  }

  Future<void> _pullCategories(
    ApiClient api,
    AppDatabase db,
    DateTime since,
  ) async {
    try {
      final dtos = await ProductRemoteSource(api).fetchCategories();
      await db.transaction(() async {
        for (final dto in dtos) {
          await db
              .into(db.categoriesTable)
              .insertOnConflictUpdate(
                CategoriesTableCompanion(
                  id: Value(dto.id),
                  name: Value(dto.name),
                  description: Value(dto.description),
                  sortOrder: Value(dto.sortOrder),
                  createdAt: Value(
                    DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
                  ),
                ),
              );
        }
      });
    } catch (e) {
      AppLogger.e('[SyncEngine] pullCategories: $e');
    }
  }

  Future<void> _pullProducts(
    ApiClient api,
    AppDatabase db,
    DateTime since,
  ) async {
    try {
      final dtos = await ProductRemoteSource(api).fetchProductsSince(since);
      await db.transaction(() async {
        for (final dto in dtos) {
          await db
              .into(db.productsTable)
              .insertOnConflictUpdate(
                ProductsTableCompanion(
                  id: Value(dto.id),
                  name: Value(dto.name),
                  description: Value(dto.description),
                  price: Value(dto.price),
                  categoryId: Value(dto.categoryId),
                  imageUrl: Value(dto.imageUrl),
                  isAvailable: Value(dto.isAvailable),
                  createdAt: Value(
                    DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
                  ),
                  updatedAt: Value(
                    DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
                  ),
                ),
              );
        }
      });
    } catch (e) {
      AppLogger.e('[SyncEngine] pullProducts: $e');
    }
  }

  Future<void> _pullCustomers(
    ApiClient api,
    AppDatabase db,
    DateTime since,
  ) async {
    try {
      final dtos = await CustomerRemoteSource(api).fetchCustomersSince(since);
      await db.transaction(() async {
        for (final dto in dtos) {
          await db
              .into(db.customersTable)
              .insertOnConflictUpdate(
                CustomersTableCompanion(
                  id: Value(dto.id),
                  name: Value(dto.name),
                  email: Value(dto.email),
                  phone: Value(dto.phone),
                  qrCode: Value(dto.qrCode),
                  totalStamps: Value(dto.totalStamps),
                  rewardsRedeemed: Value(dto.rewardsRedeemed),
                  createdAt: Value(
                    DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
                  ),
                  updatedAt: Value(
                    DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
                  ),
                ),
              );
        }
      });
    } catch (e) {
      AppLogger.e('[SyncEngine] pullCustomers: $e');
    }
  }

  Future<void> _pullReservations(
    ApiClient api,
    AppDatabase db,
    DateTime since,
  ) async {
    try {
      final dtos = await ReservationRemoteSource(
        api,
      ).fetchReservationsSince(since);
      await db.transaction(() async {
        for (final dto in dtos) {
          await db
              .into(db.reservationsTable)
              .insertOnConflictUpdate(
                ReservationsTableCompanion(
                  id: Value(dto.id),
                  customerName: Value(dto.customerName),
                  customerPhone: Value(dto.customerPhone),
                  tableId: Value(dto.tableId),
                  partySize: Value(dto.partySize),
                  reservationDate: Value(
                    DateTime.tryParse(dto.reservationDate) ?? DateTime.now(),
                  ),
                  reservationTime: Value(
                    DateTime.tryParse(dto.reservationTime) ?? DateTime.now(),
                  ),
                  status: Value(dto.status),
                  notes: Value(dto.notes),
                  handledBy: Value(dto.handledBy),
                  rejectionReason: Value(dto.rejectionReason),
                  createdAt: Value(
                    DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
                  ),
                  updatedAt: Value(
                    DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
                  ),
                ),
              );
        }
      });
    } catch (e) {
      AppLogger.e('[SyncEngine] pullReservations: $e');
    }
  }

  Future<void> _pullTables(
    ApiClient api,
    AppDatabase db,
    DateTime since,
  ) async {
    try {
      final dtos = await TableRemoteSource(api).fetchTablesSince(since);
      await db.transaction(() async {
        for (final dto in dtos) {
          await db
              .into(db.cafeTablesTable)
              .insertOnConflictUpdate(
                CafeTablesTableCompanion(
                  id: Value(dto.id),
                  label: Value(dto.label),
                  capacity: Value(dto.capacity),
                  status: Value(dto.status),
                  currentOrderId: Value(dto.currentOrderId),
                ),
              );
        }
      });
    } catch (e) {
      AppLogger.e('[SyncEngine] pullTables: $e');
    }
  }

  Future<void> _pullInventory(
    ApiClient api,
    AppDatabase db,
    DateTime since,
  ) async {
    try {
      final dtos = await InventoryRemoteSource(api).fetchInventorySince(since);
      await db.transaction(() async {
        for (final dto in dtos) {
          await db
              .into(db.inventoryTable)
              .insertOnConflictUpdate(
                InventoryTableCompanion(
                  id: Value(dto.id),
                  productId: Value(dto.productId),
                  productName: Value(dto.productName),
                  currentStock: Value(dto.currentStock),
                  minStock: Value(dto.minStock),
                  unit: Value(dto.unit),
                  lastRestocked: Value(
                    DateTime.tryParse(dto.lastRestocked) ?? DateTime.now(),
                  ),
                ),
              );
        }
      });
    } catch (e) {
      AppLogger.e('[SyncEngine] pullInventory: $e');
    }
  }

  Future<void> _pullRewards(
    ApiClient api,
    AppDatabase db,
    DateTime since,
  ) async {
    try {
      final dtos = await RewardRemoteSource(api).fetchRewardsSince(since);
      await db.transaction(() async {
        for (final dto in dtos) {
          await db
              .into(db.rewardsTable)
              .insertOnConflictUpdate(
                RewardsTableCompanion(
                  id: Value(dto.id),
                  name: Value(dto.name),
                  description: Value(dto.description),
                  stampsRequired: Value(dto.stampsRequired),
                  isActive: Value(dto.isActive),
                  code: Value(dto.code),
                  customerId: Value(dto.customerId),
                  isClaimed: Value(dto.isClaimed),
                  claimedByStaffId: Value(dto.claimedByStaffId),
                  claimedAt: Value(
                    dto.claimedAt != null
                        ? DateTime.tryParse(dto.claimedAt!)
                        : null,
                  ),
                  createdAt: Value(
                    DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
                  ),
                ),
              );
        }
      });
    } catch (e) {
      AppLogger.e('[SyncEngine] pullRewards: $e');
    }
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final syncEngineProvider = Provider<SyncEngine>((ref) => SyncEngine(ref));
