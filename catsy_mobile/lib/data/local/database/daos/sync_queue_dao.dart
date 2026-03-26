import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/tables/sync_queue_table.dart';
import 'package:catsy_pos/data/local/database/tables/sync_conflict_log_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueueTable, SyncConflictLogTable])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  // ── Watch ────────────────────────────────────────────────────────────

  Stream<int> watchPendingCount() {
    final query = selectOnly(syncQueueTable)
      ..addColumns([syncQueueTable.id.count()])
      ..where(syncQueueTable.status.equals('pending'));
    return query
        .map((row) => row.read(syncQueueTable.id.count()) ?? 0)
        .watchSingle();
  }

  Stream<int> watchFailedCount() {
    final query = selectOnly(syncQueueTable)
      ..addColumns([syncQueueTable.id.count()])
      ..where(syncQueueTable.status.equals('failed'));
    return query
        .map((row) => row.read(syncQueueTable.id.count()) ?? 0)
        .watchSingle();
  }

  // ── Read ─────────────────────────────────────────────────────────────

  /// Returns pending items ordered by priority DESC (high first), then
  /// creation order ASC (oldest first = FIFO within same priority).
  Future<List<SyncQueueTableData>> getPendingByPriority() =>
      (select(syncQueueTable)
            ..where((t) => t.status.equals('pending'))
            ..orderBy([
              (t) => OrderingTerm.desc(t.priority),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .get();

  /// Legacy accessor kept for backward compatibility.
  Future<List<SyncQueueTableData>> getPending() => getPendingByPriority();

  Future<List<SyncQueueTableData>> getFailedItems() =>
      (select(syncQueueTable)
            ..where((t) => t.status.equals('failed'))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<int> pendingCount() async => (await getPending()).length;

  // ── Conflict Log ─────────────────────────────────────────────────────

  Future<List<SyncConflictLogTableData>> getRecentConflicts({int limit = 20}) =>
      (select(syncConflictLogTable)
            ..orderBy([(t) => OrderingTerm.desc(t.resolvedAt)])
            ..limit(limit))
          .get();

  Future<void> logConflict({
    required String targetTable,
    required String entityId,
    required String localJson,
    required String remoteJson,
    required String winner,
  }) => into(syncConflictLogTable).insert(
    SyncConflictLogTableCompanion(
      id: Value(const Uuid().v4()),
      targetTable: Value(targetTable),
      entityId: Value(entityId),
      localJson: Value(localJson),
      remoteJson: Value(remoteJson),
      winner: Value(winner),
      resolvedAt: Value(DateTime.now()),
    ),
  );

  // ── Write ───────────────────────────────────────────────────────────

  Future<void> enqueue(SyncQueueTableCompanion entry) =>
      into(syncQueueTable).insert(entry);

  Future<void> markSynced(String id) =>
      (update(syncQueueTable)..where((t) => t.id.equals(id))).write(
        SyncQueueTableCompanion(
          status: const Value('synced'),
          lastAttempt: Value(DateTime.now()),
        ),
      );

  /// Increment retry count and keep status as `pending` so the item will be
  /// re-tried on the next queue run after appropriate backoff.
  Future<void> markRetry(String id) async {
    final entry = await (select(
      syncQueueTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (entry == null) return;

    await (update(syncQueueTable)..where((t) => t.id.equals(id))).write(
      SyncQueueTableCompanion(
        retryCount: Value(entry.retryCount + 1),
        lastAttempt: Value(DateTime.now()),
        // status stays 'pending' — will be retried after backoff
      ),
    );
  }

  /// Mark as permanently failed (max retries exhausted or 4xx error).
  Future<void> markFailed(String id) async {
    final entry = await (select(
      syncQueueTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (entry == null) return;

    await (update(syncQueueTable)..where((t) => t.id.equals(id))).write(
      SyncQueueTableCompanion(
        status: const Value('failed'),
        retryCount: Value(entry.retryCount + 1),
        lastAttempt: Value(DateTime.now()),
      ),
    );
  }

  /// Reset all failed items back to `pending` so staff can trigger a retry.
  Future<void> resetFailed() =>
      (update(syncQueueTable)..where((t) => t.status.equals('failed'))).write(
        const SyncQueueTableCompanion(
          status: Value('pending'),
          retryCount: Value(0),
        ),
      );
}
