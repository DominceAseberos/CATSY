import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/sync_action.dart';

/// Abstract contract for offline sync queue management.
abstract class SyncRepository {
  Future<Either<Failure, void>> enqueue(SyncAction action);
  Future<Either<Failure, List<SyncAction>>> getPendingActions();
  Future<Either<Failure, void>> markSynced(String id);
  Future<Either<Failure, void>> markFailed(String id);
  Future<Either<Failure, void>> processQueue();
  Future<int> pendingCount();
}
