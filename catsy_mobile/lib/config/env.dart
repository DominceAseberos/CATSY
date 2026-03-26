/// Environment configuration loaded at compile time via `--dart-define`.
///
/// Example: `flutter run --dart-define=API_BRIDGE_BASE_URL=http://localhost:8000`
class Env {
  Env._();

  // ── Business Rules ────────────────────────────────────────────────────
  static int get stampThreshold =>
      int.tryParse(
        const String.fromEnvironment('STAMP_THRESHOLD', defaultValue: '9'),
      ) ??
      9;

  static int get lowStockSafetyLevel =>
      int.tryParse(
        const String.fromEnvironment(
          'LOW_STOCK_SAFETY_LEVEL',
          defaultValue: '10',
        ),
      ) ??
      10;

  // ── API Bridge ────────────────────────────────────────────────────────
  static String get apiBridgeBaseUrl {
    const url = String.fromEnvironment('API_BRIDGE_BASE_URL', defaultValue: '');
    assert(url.isNotEmpty, 'API_BRIDGE_BASE_URL must be set via --dart-define');
    return url.isEmpty ? 'http://localhost:8000' : url; // localhost only survives debug
  }

  /// Optional TLS Certificate (PEM format) deployed via --dart-define for SSL pinning
  static String get apiBridgeCertPem => const String.fromEnvironment('API_BRIDGE_CERT_PEM', defaultValue: '');

  // ── App ───────────────────────────────────────────────────────────────
  static const String appName = 'CATSY POS';
  static const String appVersion = '1.0.0';

  // ── Feature Flags ─────────────────────────────────────────────────────
  static const bool enableOfflineMode = true;
  static const bool enablePrinting = true;
}
