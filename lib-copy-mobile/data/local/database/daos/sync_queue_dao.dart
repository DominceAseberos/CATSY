import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueueTable])
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

  // ── Read ─────────────────────────────────────────────────────────────
  Future<List<SyncQueueTableData>> getPending() =>
      (select(syncQueueTable)
            ..where((t) => t.status.equals('pending'))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<int> pendingCount() async {
    final items = await getPending();
    return items.length;
  }

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
}
