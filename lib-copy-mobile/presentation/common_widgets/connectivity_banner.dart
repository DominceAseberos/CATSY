import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_colors.dart';
import '../../core/network/connectivity_service.dart';

/// Banner shown at the top of the screen when the device is offline.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);

    return connectivity.when(
      data: (isOnline) {
        if (isOnline) return const SizedBox.shrink();
        return MaterialBanner(
          backgroundColor: AppColors.warning.withAlpha(25),
          leading: const Icon(Icons.wifi_off, color: AppColors.warning),
          content: const Text(
            'You are offline. Changes will sync when reconnected.',
            style: TextStyle(color: AppColors.warning),
          ),
          actions: const [SizedBox.shrink()],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}
