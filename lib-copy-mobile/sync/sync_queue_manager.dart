import 'dart:convert';

import '../core/error/failures.dart';
import '../core/network/api_client.dart';
import '../core/utils/logger.dart';
import '../data/local/database/daos/sync_queue_dao.dart';
import '../data/local/database/app_database.dart';

/// Processes the offline sync queue in FIFO order.
///
/// For each pending [SyncQueueTableData] action:
///  1. Resolves the correct API endpoint + method from targetTable + action
///  2. Calls the [ApiClient]
///  3. Marks the row as synced on success, or failed on error
class SyncQueueManager {
  final SyncQueueDao _dao;
  final ApiClient _api;

  static const int _maxRetries = 3;

  SyncQueueManager({required SyncQueueDao dao, required ApiClient api})
    : _dao = dao,
      _api = api;

  /// Map targetTable column value to a REST path prefix.
  static const _tablePaths = <String, String>{
    'orders': '/api/v1/orders',
    'reservations': '/api/v1/reservations',
    'customers': '/api/v1/customers',
    'inventory': '/api/v1/inventory',
    'tables': '/api/v1/tables',
    'rewards': '/api/v1/rewards',
    'products': '/api/v1/products',
  };

  /// Process all pending items in creation-order (FIFO).
  Future<void> processQueue() async {
    final pendingItems = await _dao.getPending();
    if (pendingItems.isEmpty) return;

    AppLogger.i(
      '[SyncQueueManager] Processing ${pendingItems.length} pending actions',
    );

    for (final item in pendingItems) {
      if (item.retryCount >= _maxRetries) {
        AppLogger.w(
          '[SyncQueueManager] Skipping ${item.id} — max retries reached',
        );
        continue;
      }

      try {
        await _executeAction(item);
        await _dao.markSynced(item.id);
        AppLogger.d(
          '[SyncQueueManager] Synced ${item.targetTable}/${item.entityId}',
        );
      } on Failure catch (f) {
        await _dao.markFailed(item.id);
        AppLogger.e('[SyncQueueManager] Failed ${item.id}: ${f.message}');
      } catch (e) {
        await _dao.markFailed(item.id);
        AppLogger.e('[SyncQueueManager] Error ${item.id}: $e');
      }
    }
  }

  Future<void> _executeAction(SyncQueueTableData item) async {
    final path = _tablePaths[item.targetTable];
    if (path == null) {
      throw ServerFailure(
        message: 'Unknown targetTable for sync: ${item.targetTable}',
      );
    }

    final payload = jsonDecode(item.payload) as Map<String, dynamic>;

    switch (item.action.toUpperCase()) {
      case 'INSERT':
        await _api.post(path, payload);
      case 'UPDATE':
        await _api.put('$path/${item.entityId}', payload);
      case 'DELETE':
        await _api.delete('$path/${item.entityId}');
      default:
        throw ServerFailure(message: 'Unknown sync action: ${item.action}');
    }
  }
}
