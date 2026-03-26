import 'package:equatable/equatable.dart';
import 'package:catsy_pos/domain/enums/sync_status.dart';

/// Offline sync queue action.
class SyncAction extends Equatable {
  final String id;
  final String tableName;
  final String entityId;
  final String action; // 'INSERT', 'UPDATE', 'DELETE'
  final Map<String, dynamic> payload;
  final SyncStatus status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttempt;

  const SyncAction({
    required this.id,
    required this.tableName,
    required this.entityId,
    required this.action,
    required this.payload,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    required this.createdAt,
    this.lastAttempt,
  });

  @override
  List<Object?> get props => [id, tableName, entityId, action, status];
}
