import 'dart:convert';

import 'package:catsy_pos/core/utils/logger.dart';
import 'package:catsy_pos/data/local/database/daos/sync_queue_dao.dart';

/// Resolves conflicts between local and remote data.
///
/// Resolution strategies (in priority order):
/// 1. **Delete-wins**: if the remote record carries `"deleted": true`, the
///    local record is deleted and the decision is logged.
/// 2. **Field-level merge for orders**: the newer `status`/`payment_status`
///    wins, while the local `notes` is preserved when the remote has none.
/// 3. **Last-Writer-Wins (LWW)**: falls back to `updated_at` timestamp
///    comparison for all other tables.
///
/// Every decision is written to [SyncConflictLogTable] via [SyncQueueDao]
/// for audit and debugging.
class ConflictResolver {
  final SyncQueueDao? _dao;

  ConflictResolver({SyncQueueDao? dao}) : _dao = dao;

  /// Convenience factory for contexts without a DAO (offline-only tests).
  const ConflictResolver.noLog() : _dao = null;

  // ── Public API ───────────────────────────────────────────────────────

  /// Resolves a conflict and returns the winning record.
  ///
  /// Returns `null` if the remote sent a tombstone (delete-wins) — the caller
  /// should delete the local record in this case.
  Future<Map<String, dynamic>?> resolve({
    required String targetTable,
    required String entityId,
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) async {
    // ── 1. Delete-wins ──────────────────────────────────────────────────
    if (remote['deleted'] == true) {
      AppLogger.d(
        '[ConflictResolver] Remote tombstone for $targetTable/$entityId → DELETE',
      );
      await _log(
        targetTable: targetTable,
        entityId: entityId,
        local: local,
        remote: remote,
        winner: 'remote_delete',
      );
      return null; // caller must delete local record
    }

    // ── 2. Field-level merge for orders ─────────────────────────────────
    if (targetTable == 'orders') {
      return _mergeOrder(
        targetTable: targetTable,
        entityId: entityId,
        local: local,
        remote: remote,
      );
    }

    // ── 3. LWW fallback ─────────────────────────────────────────────────
    return _lww(
      targetTable: targetTable,
      entityId: entityId,
      local: local,
      remote: remote,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> _lww({
    required String targetTable,
    required String entityId,
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) async {
    final localTime = DateTime.tryParse(local['updated_at']?.toString() ?? '');
    final remoteTime = DateTime.tryParse(
      remote['updated_at']?.toString() ?? '',
    );

    if (localTime == null && remoteTime == null) {
      AppLogger.w(
        '[ConflictResolver] Both timestamps null for $targetTable/$entityId → remote',
      );
      await _log(
        targetTable: targetTable,
        entityId: entityId,
        local: local,
        remote: remote,
        winner: 'remote',
      );
      return remote;
    }

    if (localTime == null) {
      await _log(
        targetTable: targetTable,
        entityId: entityId,
        local: local,
        remote: remote,
        winner: 'remote',
      );
      return remote;
    }
    if (remoteTime == null) {
      await _log(
        targetTable: targetTable,
        entityId: entityId,
        local: local,
        remote: remote,
        winner: 'local',
      );
      return local;
    }

    final localWins = localTime.isAfter(remoteTime);
    final winner = localWins ? local : remote;
    final winnerLabel = localWins ? 'local' : 'remote';
    AppLogger.d(
      '[ConflictResolver] $targetTable/$entityId — local=$localTime '
      'remote=$remoteTime → $winnerLabel wins',
    );
    await _log(
      targetTable: targetTable,
      entityId: entityId,
      local: local,
      remote: remote,
      winner: winnerLabel,
    );
    return winner;
  }

  /// Field-level merge for order records:
  /// - `status` and `payment_status` come from whichever record is newer
  /// - `notes` keeps the local value if the remote is null
  /// - All other fields follow LWW
  Future<Map<String, dynamic>> _mergeOrder({
    required String targetTable,
    required String entityId,
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) async {
    final localTime = DateTime.tryParse(local['updated_at']?.toString() ?? '');
    final remoteTime = DateTime.tryParse(
      remote['updated_at']?.toString() ?? '',
    );

    final Map<String, dynamic> base;
    if (localTime != null &&
        remoteTime != null &&
        localTime.isAfter(remoteTime)) {
      base = Map<String, dynamic>.from(local);
    } else {
      base = Map<String, dynamic>.from(remote);
    }

    // Preserve local notes when remote has none
    if ((remote['notes'] == null || remote['notes'].toString().isEmpty) &&
        local['notes'] != null &&
        local['notes'].toString().isNotEmpty) {
      base['notes'] = local['notes'];
    }

    AppLogger.d('[ConflictResolver] orders/$entityId → field-level merge');
    await _log(
      targetTable: targetTable,
      entityId: entityId,
      local: local,
      remote: remote,
      winner: 'merged',
    );
    return base;
  }

  Future<void> _log({
    required String targetTable,
    required String entityId,
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
    required String winner,
  }) async {
    if (_dao == null) return;
    try {
      await _dao.logConflict(
        targetTable: targetTable,
        entityId: entityId,
        localJson: jsonEncode(local),
        remoteJson: jsonEncode(remote),
        winner: winner,
      );
    } catch (e) {
      AppLogger.w('[ConflictResolver] Failed to log conflict: $e');
    }
  }
}
