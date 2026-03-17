import 'package:flutter/services.dart';

/// A unified utility for triggering system haptic feedback across the app.
class AppHaptics {
  AppHaptics._();

  /// Very brief vibration, used for standard taps (e.g., product card, navigation limit).
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium vibration, used for important actions like confirming a payment.
  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy vibration for critical errors or highly destructive items.
  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// System default selection click.
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
