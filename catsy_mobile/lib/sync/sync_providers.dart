import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rich state exposed to the UI for sync progress and health.
class SyncStatusState {
  final bool isSyncing;
  final DateTime? lastSyncAt;
  final int pendingCount;
  final int failedCount;
  final double progress; // 0.0 → 1.0 for full-sync progress
  final String?
  currentStep; // Human-readable step label, e.g. "Pulling orders…"

  const SyncStatusState({
    this.isSyncing = false,
    this.lastSyncAt,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.progress = 0.0,
    this.currentStep,
  });

  SyncStatusState copyWith({
    bool? isSyncing,
    DateTime? lastSyncAt,
    int? pendingCount,
    int? failedCount,
    double? progress,
    String? currentStep,
    bool clearStep = false,
  }) => SyncStatusState(
    isSyncing: isSyncing ?? this.isSyncing,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    pendingCount: pendingCount ?? this.pendingCount,
    failedCount: failedCount ?? this.failedCount,
    progress: progress ?? this.progress,
    currentStep: clearStep ? null : (currentStep ?? this.currentStep),
  );
}

/// Notifier holding the full sync status used by the UI.
class SyncStatusNotifier extends Notifier<SyncStatusState> {
  @override
  SyncStatusState build() => const SyncStatusState();

  void setSyncing(bool value) {
    state = state.copyWith(
      isSyncing: value,
      // Reset progress when done
      progress: value ? state.progress : 0.0,
      clearStep: !value,
    );
  }

  void setProgress(double progress, String step) {
    state = state.copyWith(progress: progress, currentStep: step);
  }

  void setLastSyncAt(DateTime at) {
    state = state.copyWith(lastSyncAt: at);
  }

  void updateCounts({required int pending, required int failed}) {
    state = state.copyWith(pendingCount: pending, failedCount: failed);
  }

  void incrementFailedAlert() {
    state = state.copyWith(failedCount: state.failedCount + 1);
  }
}

/// Provider for the rich sync status.
final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatusState>(
      SyncStatusNotifier.new,
    );

// ── Legacy shim ───────────────────────────────────────────────────────────────
// Kept so existing widgets that watch isSyncingProvider continue to work.

class IsSyncingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setSyncing(bool value) => state = value;
}

/// Global provider for backward-compatible [IsSyncingNotifier].
final isSyncingProvider = NotifierProvider<IsSyncingNotifier, bool>(
  IsSyncingNotifier.new,
);
