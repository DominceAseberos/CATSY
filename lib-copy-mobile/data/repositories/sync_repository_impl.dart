import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../core/error/failures.dart';
import '../../domain/entities/sync_action.dart';
import '../../domain/enums/sync_status.dart';
import '../../domain/repositories/sync_repository.dart';
import '../local/database/daos/sync_queue_dao.dart';
import '../local/database/app_database.dart';

/// Phase 1 — LOCAL ONLY. Queues actions but does not process them remotely.
class SyncRepositoryImpl implements SyncRepository {
  final SyncQueueDao _syncQueueDao;

  SyncRepositoryImpl({required SyncQueueDao syncQueueDao})
    : _syncQueueDao = syncQueueDao;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, void>> enqueue(SyncAction action) async {
    try {
      await _syncQueueDao.enqueue(
        SyncQueueTableCompanion(
          id: Value(action.id.isEmpty ? _uuid.v4() : action.id),
          targetTable: Value(action.tableName),
          entityId: Value(action.entityId),
          action: Value(action.action),
          payload: Value(jsonEncode(action.payload)),
          status: Value(action.status.name),
          retryCount: Value(action.retryCount),
          createdAt: Value(action.createdAt),
        ),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to enqueue sync action: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SyncAction>>> getPendingActions() async {
    try {
      final rows = await _syncQueueDao.getPending();
      return Right(rows.map(_mapToSyncAction).toList());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get pending actions: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markSynced(String id) async {
    try {
      await _syncQueueDao.markSynced(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to mark synced: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markFailed(String id) async {
    try {
      await _syncQueueDao.markFailed(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to mark failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> processQueue() async {
    // Phase 1: No-op — actual sync processing added in Phase 12.
    return const Right(null);
  }

  @override
  Future<int> pendingCount() async {
    return _syncQueueDao.pendingCount();
  }

  SyncAction _mapToSyncAction(SyncQueueTableData r) => SyncAction(
    id: r.id,
    tableName: r.targetTable,
    entityId: r.entityId,
    action: r.action,
    payload: _decodePayload(r.payload),
    status: SyncStatus.values.firstWhere(
      (e) => e.name == r.status,
      orElse: () => SyncStatus.pending,
    ),
    retryCount: r.retryCount,
    createdAt: r.createdAt,
    lastAttempt: r.lastAttempt,
  );

  Map<String, dynamic> _decodePayload(String payload) {
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
