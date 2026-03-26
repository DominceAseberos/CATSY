import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a single instance of ConnectivityService
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provides a stream of connectivity status.
///
/// `true` → device is online, `false` → offline.
final connectivityProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onConnectivityChanged;
});

/// One-shot check for current connectivity.
final isOnlineProvider = FutureProvider<bool>((ref) async {
  return ref.watch(connectivityServiceProvider).isConnected;
});

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream that emits `true` when the device has an internet connection.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (results) => !results.contains(ConnectivityResult.none),
    );
  }

  /// Checks the current connectivity status once.
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
