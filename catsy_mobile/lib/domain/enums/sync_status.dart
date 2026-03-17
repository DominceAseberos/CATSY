/// Offline sync queue item status.
enum SyncStatus {
  pending,
  syncing,
  synced,
  failed;

  String get label => switch (this) {
    SyncStatus.pending => 'Pending',
    SyncStatus.syncing => 'Syncing',
    SyncStatus.synced => 'Synced',
    SyncStatus.failed => 'Failed',
  };
}
