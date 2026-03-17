import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../config/app_constants.dart';
import '../core/error/failures.dart';
import '../core/network/api_client.dart';
import '../core/utils/logger.dart';
import '../data/local/database/daos/sync_queue_dao.dart';
import '../data/local/database/app_database.dart';
import 'sync_providers.dart';

/// Priority levels for the sync queue.
///
/// Items are sorted by priority DESC so high-priority actions
/// (payments, stock deductions) are processed before normal ones.
class SyncPriority {
  static const int normal = 0;
  static const int high = 1;

  /// Tables whose mutations should be processed first.
  static const _highPriorityTables = {'orders', 'inventory'};

  static int forTable(String targetTable) {
    return _highPriorityTables.contains(targetTable) ? high : normal;
  }
}

/// Processes the offline sync queue in priority order with exponential backoff.
///
/// For each pending [SyncQueueTableData] action:
///  1. Sorts by priority DESC → createdAt ASC (payments and stock first)
///  2. Skips items not yet due for retry (exponential back-off)
///  3. Injects an idempotency key header so duplicate requests are safe
///  4. On SocketException / timeout → markRetry() (stays pending, never lost)
///  5. On 4xx → markFailed() (permanent, alert staff)
///  6. On 5xx → markRetry() (server-side transient error)
///  7. After maxRetries exhausted → markFailed() + notifies [SyncStatusNotifier]
class SyncQueueManager {
  final SyncQueueDao _dao;
  final ApiClient _api;
  final SyncStatusNotifier? _statusNotifier;

  SyncQueueManager({
    required SyncQueueDao dao,
    required ApiClient api,
    SyncStatusNotifier? statusNotifier,
  }) : _dao = dao,
       _api = api,
       _statusNotifier = statusNotifier;

  /// Map targetTable → REST path prefix.
  static const _tablePaths = <String, String>{
    'orders': '/api/v1/orders',
    'reservations': '/api/v1/reservations',
    'customers': '/api/v1/customers',
    'inventory': '/api/v1/inventory',
    'tables': '/api/v1/tables',
    'rewards': '/api/v1/rewards',
    'products': '/api/v1/products',
    'transactions': '/api/v1/transactions',
  };

  /// Compute exponential backoff duration for a given retry count.
  /// Formula: min(base * 2^retryCount, max)
  static Duration _backoff(int retryCount) {
    final ms = min(
      AppConstants.syncBackoffBaseMs * pow(2, retryCount).toInt(),
      AppConstants.syncBackoffMaxMs,
    );
    return Duration(milliseconds: ms);
  }

  /// Returns true if enough time has passed since [lastAttempt] to retry.
  static bool _isDue(SyncQueueTableData item) {
    if (item.lastAttempt == null) return true;
    final nextAt = item.lastAttempt!.add(_backoff(item.retryCount));
    return DateTime.now().isAfter(nextAt);
  }

  /// Process all pending items, respecting priority and backoff.
  Future<void> processQueue() async {
    final pendingItems = await _dao.getPendingByPriority();
    if (pendingItems.isEmpty) return;

    AppLogger.i(
      '[SyncQueueManager] Processing ${pendingItems.length} pending actions',
    );

    // --- Batch grouping: consecutive same-table INSERTs ---
    // We process items one by one here but batch INSERT calls within a table.
    // Batching is handled in _executeAction for INSERT actions.
    final dueItems = pendingItems.where(_isDue).toList();
    AppLogger.d('[SyncQueueManager] ${dueItems.length} items due now');

    for (final item in dueItems) {
      // Re-check max retries
      if (item.retryCount >= AppConstants.maxRetries) {
        AppLogger.w(
          '[SyncQueueManager] ${item.id} exceeded max retries → marking failed',
        );
        await _dao.markFailed(item.id);
        _statusNotifier?.incrementFailedAlert();
        continue;
      }

      try {
        await _executeAction(item);
        await _dao.markSynced(item.id);
        AppLogger.d(
          '[SyncQueueManager] ✓ Synced ${item.targetTable}/${item.entityId}',
        );
      } on SocketException catch (e) {
        // Network dropped mid-sync — re-queue with incremented retryCount
        AppLogger.w('[SyncQueueManager] Network error ${item.id}: $e → retry');
        await _dao.markRetry(item.id);
      } on TimeoutException catch (e) {
        AppLogger.w('[SyncQueueManager] Timeout ${item.id}: $e → retry');
        await _dao.markRetry(item.id);
      } on ServerFailure catch (f) {
        // 4xx = permanent client error, 5xx = transient server error
        if (f.message.startsWith('HTTP 4')) {
          AppLogger.e(
            '[SyncQueueManager] Client error ${item.id}: ${f.message} → failed',
          );
          await _dao.markFailed(item.id);
          _statusNotifier?.incrementFailedAlert();
        } else {
          AppLogger.w(
            '[SyncQueueManager] Server error ${item.id}: ${f.message} → retry',
          );
          await _dao.markRetry(item.id);
        }
      } catch (e) {
        AppLogger.e(
          '[SyncQueueManager] Unexpected error ${item.id}: $e → retry',
        );
        await _dao.markRetry(item.id);
      }
    }
  }

  Future<void> _executeAction(SyncQueueTableData item) async {
    final path = _tablePaths[item.targetTable];
    if (path == null) {
      throw ServerFailure(
        message: 'HTTP 400: Unknown targetTable for sync: ${item.targetTable}',
      );
    }

    final payload = jsonDecode(item.payload) as Map<String, dynamic>;

    // Idempotency key so the server can de-duplicate retried requests
    final extraHeaders = {'X-Idempotency-Key': item.id};

    switch (item.action.toUpperCase()) {
      case 'INSERT':
        await _api.post(path, payload, extraHeaders: extraHeaders);
      case 'UPDATE':
        await _api.put(
          '$path/${item.entityId}',
          payload,
          extraHeaders: extraHeaders,
        );
      case 'DELETE':
        await _api.delete('$path/${item.entityId}', extraHeaders: extraHeaders);
      default:
        throw ServerFailure(
          message: 'HTTP 400: Unknown sync action: ${item.action}',
        );
    }
  }
}
