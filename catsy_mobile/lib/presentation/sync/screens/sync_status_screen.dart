import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../sync/sync_engine.dart';
import '../../../sync/sync_providers.dart';
import '../../../data/local/database/app_database.dart';

/// Full-screen sync status panel.
///
/// Shows:
/// - Last sync timestamp
/// - Pending and failed item counts
/// - Force Sync and Retry Failed action buttons
/// - Last 20 conflict log entries
class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  bool _isForcing = false;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(syncStatusProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _forceSync,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Status card ──────────────────────────────────────────────
            _StatusCard(status: status, colors: colors),
            const SizedBox(height: 16),

            // ── Action buttons ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: status.isSyncing || _isForcing
                        ? null
                        : _forceSync,
                    icon: status.isSyncing || _isForcing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: const Text('Force Sync'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: status.failedCount == 0 || status.isSyncing
                        ? null
                        : _retryFailed,
                    icon: const Icon(Icons.refresh),
                    label: Text('Retry Failed (${status.failedCount})'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: status.failedCount > 0
                          ? colors.error
                          : colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Live progress ────────────────────────────────────────────
            if (status.isSyncing) ...[
              Text('Progress', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: status.progress > 0 ? status.progress : null,
              ),
              if (status.currentStep != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    status.currentStep!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 24),
            ],

            // ── Conflict log ─────────────────────────────────────────────
            _ConflictLogSection(),
          ],
        ),
      ),
    );
  }

  Future<void> _forceSync() async {
    setState(() => _isForcing = true);
    try {
      await ref.read(syncEngineProvider).onLogin();
    } finally {
      if (mounted) setState(() => _isForcing = false);
    }
  }

  Future<void> _retryFailed() async {
    final db = ref.read(appDatabaseProvider);
    await db.syncQueueDao.resetFailed();
    await _forceSync();
  }
}

// ── Status summary card ────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final SyncStatusState status;
  final ColorScheme colors;

  const _StatusCard({required this.status, required this.colors});

  @override
  Widget build(BuildContext context) {
    final lastSync = status.lastSyncAt;
    final fmt = DateFormat('MMM d, y · h:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.isSyncing ? Icons.sync : Icons.check_circle_outline,
                  color: status.isSyncing ? colors.primary : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  status.isSyncing ? 'Syncing…' : 'Idle',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            _Row(
              label: 'Last sync',
              value: lastSync != null
                  ? fmt.format(lastSync.toLocal())
                  : 'Never',
            ),
            const SizedBox(height: 8),
            _Row(
              label: 'Pending items',
              value: status.pendingCount.toString(),
              valueColor: status.pendingCount > 0 ? colors.primary : null,
            ),
            const SizedBox(height: 8),
            _Row(
              label: 'Failed items',
              value: status.failedCount.toString(),
              valueColor: status.failedCount > 0 ? colors.error : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ── Conflict log section ───────────────────────────────────────────────────

class _ConflictLogSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    return FutureBuilder(
      future: db.syncQueueDao.getRecentConflicts(limit: 20),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final conflicts = snapshot.data!;
        if (conflicts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conflict Log (last ${conflicts.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...conflicts.map(
              (c) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    _iconForWinner(c.winner),
                    color: _colorForWinner(
                      c.winner,
                      Theme.of(context).colorScheme,
                    ),
                    size: 20,
                  ),
                  title: Text(
                    '${c.targetTable} · ${c.entityId.substring(0, 8)}…',
                  ),
                  subtitle: Text(
                    '${_labelForWinner(c.winner)} · '
                    '${DateFormat('MMM d h:mm a').format(c.resolvedAt.toLocal())}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconForWinner(String winner) => switch (winner) {
    'local' => Icons.phone_android,
    'remote' => Icons.cloud_done,
    'merged' => Icons.merge,
    'remote_delete' => Icons.delete_sweep,
    _ => Icons.help_outline,
  };

  Color _colorForWinner(String winner, ColorScheme cs) => switch (winner) {
    'local' => cs.primary,
    'remote' => Colors.green,
    'merged' => Colors.orange,
    'remote_delete' => cs.error,
    _ => cs.onSurface,
  };

  String _labelForWinner(String winner) => switch (winner) {
    'local' => 'Local won',
    'remote' => 'Remote won',
    'merged' => 'Merged',
    'remote_delete' => 'Remote deleted',
    _ => winner,
  };
}
