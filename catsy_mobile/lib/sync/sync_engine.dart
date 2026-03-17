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
import 'sync_providers.dart';
import 'sync_queue_manager.dart';

/// Orchestrates all sync operations with three lifecycle hooks:
///
/// - [onLogin]   → full pull via pagination then push any queued mutations
/// - [onLogout]  → push remaining queue (if online) before clearing session
/// - [start]     → connectivity watcher + periodic 5-min sync
///
/// The golden rule is: push queue FIRST, then pull fresh data.
/// This ensures locally created records reach the server before we overwrite
/// them with older remote data.
class SyncEngine {
  final Ref _ref;
  Timer? _periodicTimer;
  StreamSubscription<bool>? _connectivitySub;

  SyncEngine(this._ref);

  // ── Helpers ────────────────────────────────────────────────────────────

  AppDatabase get _db => _ref.read(appDatabaseProvider);
  ApiClient get _api => _ref.read(apiClientProvider);
  SecureStorageService get _storage => _ref.read(secureStorageServiceProvider);
  SyncStatusNotifier get _status => _ref.read(syncStatusProvider.notifier);
  IsSyncingNotifier get _legacySyncing => _ref.read(isSyncingProvider.notifier);

  SyncQueueManager get _queueManager => SyncQueueManager(
    dao: _db.syncQueueDao,
    api: _api,
    statusNotifier: _status,
  );

  // ── Concurrency Guard ──────────────────────────────────────────────────

  Completer<void>? _syncLock;

  Future<void> _guardedSync(Future<void> Function() body) async {
    if (_syncLock != null) {
      AppLogger.d('[SyncEngine] Sync already in progress, skipping');
      return;
    }
    _syncLock = Completer<void>();
    try {
      await body();
    } finally {
      if (!_syncLock!.isCompleted) _syncLock!.complete();
      _syncLock = null;
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────

  /// Call once after user logs in.
  ///
  /// Runs a full paginated pull of all resources, then drains the queue so
  /// any optimistic mutations created offline reach the server.
  Future<void> onLogin() async {
    final isOnline = await ConnectivityService().isConnected;
    if (!isOnline) {
      AppLogger.i('[SyncEngine] Login sync skipped — offline');
      return;
    }
    await _guardedSync(() async {
      AppLogger.i('[SyncEngine] onLogin → full pull + push');
      _setSyncing(true);
      try {
        await _fullPull();
        await _pushPendingActions();
        await _storage.saveLastSyncTimestamp(DateTime.now());
        _status.setLastSyncAt(DateTime.now());
      } finally {
        _setSyncing(false);
      }
    });
  }

  /// Call before the session is cleared on logout.
  ///
  /// Pushes any remaining queued mutations so data is not lost.
  Future<void> onLogout() async {
    final isOnline = await ConnectivityService().isConnected;
    if (!isOnline) {
      AppLogger.i('[SyncEngine] Logout sync skipped — offline');
      return;
    }
    await _guardedSync(() async {
      AppLogger.i('[SyncEngine] onLogout → final push');
      try {
        await _pushPendingActions();
      } catch (e) {
        AppLogger.e('[SyncEngine] onLogout push error: $e');
      }
    });
  }

  /// Starts the background sync engine:
  /// 1. Watches connectivity — triggers push+pull when coming online
  /// 2. Schedules a periodic incremental sync every 5 minutes
  void start() {
    AppLogger.i('[SyncEngine] Starting…');
    _connectivitySub = ConnectivityService().onConnectivityChanged.listen((
      isOnline,
    ) {
      if (isOnline) {
        AppLogger.i('[SyncEngine] Back online → push + incremental pull');
        _onConnectivityRestored();
      }
    });
    _periodicTimer = Timer.periodic(AppConstants.syncInterval, (_) {
      _incrementalSync();
    });
  }

  void stop() {
    AppLogger.i('[SyncEngine] Stopping…');
    _periodicTimer?.cancel();
    _connectivitySub?.cancel();
  }

  // ── Connectivity restored ──────────────────────────────────────────────

  Future<void> _onConnectivityRestored() async {
    await _guardedSync(() async {
      _setSyncing(true);
      try {
        await _pushPendingActions();
        await _incrementalPull();
        await _storage.saveLastSyncTimestamp(DateTime.now());
        _status.setLastSyncAt(DateTime.now());
      } finally {
        _setSyncing(false);
      }
    });
  }

  // ── Incremental sync (periodic) ────────────────────────────────────────

  Future<void> _incrementalSync() async {
    final isOnline = await ConnectivityService().isConnected;
    if (!isOnline) return;
    await _guardedSync(() async {
      _setSyncing(true);
      try {
        AppLogger.d('[SyncEngine] Periodic incremental sync…');
        await _pushPendingActions();
        await _incrementalPull();
        await _storage.saveLastSyncTimestamp(DateTime.now());
        _status.setLastSyncAt(DateTime.now());
      } finally {
        _setSyncing(false);
      }
    });
  }

  // ── Push ───────────────────────────────────────────────────────────────

  Future<void> _pushPendingActions() async {
    try {
      await _queueManager.processQueue();
      // Update counts after push
      final pending = await _db.syncQueueDao.pendingCount();
      final failed = (await _db.syncQueueDao.getFailedItems()).length;
      _status.updateCounts(pending: pending, failed: failed);
    } catch (e) {
      AppLogger.e('[SyncEngine] Push failed: $e');
    }
  }

  // ── Full pull (paginated) ──────────────────────────────────────────────

  /// Performs a paginated full pull of all resource types.
  /// Uses since=epoch so all records are fetched.
  Future<void> _fullPull() async {
    AppLogger.i('[SyncEngine] Full pull started…');
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final steps = [
      ('Pulling orders…', () => _pullOrders(_api, _db, epoch)),
      ('Pulling products…', () => _pullProducts(_api, _db, epoch)),
      ('Pulling categories…', () => _pullCategories(_api, _db, epoch)),
      ('Pulling customers…', () => _pullCustomers(_api, _db, epoch)),
      ('Pulling reservations…', () => _pullReservations(_api, _db, epoch)),
      ('Pulling tables…', () => _pullTables(_api, _db, epoch)),
      ('Pulling inventory…', () => _pullInventory(_api, _db, epoch)),
      ('Pulling rewards…', () => _pullRewards(_api, _db, epoch)),
    ];

    for (var i = 0; i < steps.length; i++) {
      final (label, fn) = steps[i];
      _status.setProgress((i / steps.length), label);
      await fn();
    }
    _status.setProgress(1.0, 'Sync complete');
    AppLogger.i('[SyncEngine] Full pull done');
  }

  // ── Incremental pull ──────────────────────────────────────────────────

  Future<void> _incrementalPull() async {
    final lastSync = await _storage.getLastSyncTimestamp();
    final since = lastSync ?? DateTime.fromMillisecondsSinceEpoch(0);
    AppLogger.d('[SyncEngine] Incremental pull since $since');

    await Future.wait([
      _pullOrders(_api, _db, since),
      _pullProducts(_api, _db, since),
      _pullCategories(_api, _db, since),
      _pullCustomers(_api, _db, since),
      _pullReservations(_api, _db, since),
      _pullTables(_api, _db, since),
      _pullInventory(_api, _db, since),
      _pullRewards(_api, _db, since),
    ]);

    AppLogger.i('[SyncEngine] Incremental pull complete');
  }

  // ── Syncing state helpers ─────────────────────────────────────────────

  void _setSyncing(bool value) {
    _status.setSyncing(value);
    _legacySyncing.setSyncing(value);
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
