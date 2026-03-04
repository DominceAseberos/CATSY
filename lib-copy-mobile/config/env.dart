import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loaded from `.env` at runtime.
///
/// Values are available AFTER calling `await dotenv.load()` in `main()`.
class Env {
  Env._();

  // ── Business Rules ────────────────────────────────────────────────────
  static int get stampThreshold =>
      int.tryParse(dotenv.env['STAMP_THRESHOLD'] ?? '') ?? 9;

  static int get lowStockSafetyLevel =>
      int.tryParse(dotenv.env['LOW_STOCK_SAFETY_LEVEL'] ?? '') ?? 10;

  // ── API Bridge ────────────────────────────────────────────────────────
  static String get apiBridgeBaseUrl =>
      dotenv.env['API_BRIDGE_BASE_URL'] ?? 'http://localhost:8000';

  // ── App ───────────────────────────────────────────────────────────────
  static const String appName = 'CATSY POS';
  static const String appVersion = '1.0.0';

  // ── Feature Flags ─────────────────────────────────────────────────────
  static const bool enableOfflineMode = true;
  static const bool enablePrinting = true;
}
