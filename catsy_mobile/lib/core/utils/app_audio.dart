import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'logger.dart';

/// Centralized utility to play sound effects across the app.
class AppAudio {
  AppAudio._();

  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  /// Helper to play an asset audio file safely.
  static Future<void> _playAsset(String path) async {
    try {
      await _player.stop(); // Stop any currently playing short
      await _player.play(AssetSource(path));
    } catch (e) {
      AppLogger.w('[AppAudio] Failed to play $path: $e');
    }
  }

  /// Plays a success chime. Used during payment confirmations or earning rewards.
  static Future<void> playSuccess() async {
    // Falls back to system click if asset isn't added yet, or play the asset.
    await _playAsset('audio/success.mp3');
  }

  /// Plays a short beep. Used during QR code scanning or barcode reading.
  static Future<void> playBeep() async {
    await _playAsset('audio/beep.mp3');
  }

  /// Plays a general notification ping. Used for in-app alerts (e.g., new reservation).
  static Future<void> playNotification() async {
    await _playAsset('audio/notification.mp3');
  }

  /// Plays a system click sound.
  static Future<void> playSystemClick() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }
}
