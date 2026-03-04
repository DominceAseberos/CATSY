import '../core/utils/logger.dart';

/// Resolves conflicts between local and remote data using
/// Last-Writer-Wins (LWW) based on `updatedAt` timestamps.
class ConflictResolver {
  /// Given a local record and a remote record (as JSON maps),
  /// returns the one that should win.
  Map<String, dynamic> resolve(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final localTime = DateTime.tryParse(local['updated_at'] ?? '');
    final remoteTime = DateTime.tryParse(remote['updated_at'] ?? '');

    if (localTime == null && remoteTime == null) {
      AppLogger.w(
        '[ConflictResolver] Both timestamps null — defaulting to remote',
      );
      return remote;
    }
    if (localTime == null) return remote;
    if (remoteTime == null) return local;

    final winner = localTime.isAfter(remoteTime) ? local : remote;
    AppLogger.d(
      '[ConflictResolver] local=$localTime  remote=$remoteTime → '
      '${winner == local ? "LOCAL" : "REMOTE"} wins',
    );
    return winner;
  }
}
