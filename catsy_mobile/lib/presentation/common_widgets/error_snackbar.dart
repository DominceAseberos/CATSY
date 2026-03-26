import 'package:flutter/material.dart';

import 'package:catsy_pos/config/theme/app_colors.dart';

class ErrorSnackBar extends SnackBar {
  ErrorSnackBar({super.key, required String message, VoidCallback? onRetry})
    : super(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      );

  /// Helper to easily show the snackbar
  static void show(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(ErrorSnackBar(message: message, onRetry: onRetry));
  }
}
