import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier that tracks whether a background sync operation is in progress.
class IsSyncingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setSyncing(bool value) {
    state = value;
  }
}

/// Global provider for [IsSyncingNotifier].
final isSyncingProvider = NotifierProvider<IsSyncingNotifier, bool>(
  IsSyncingNotifier.new,
);
