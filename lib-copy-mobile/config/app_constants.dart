/// Application-wide constants and magic numbers.
class AppConstants {
  AppConstants._();

  // ── Loyalty / Stamps ──────────────────────────────────────────────────
  static const int stampsPerReward = 10;
  static const int maxStampsPerTransaction = 1;

  // ── Sync ──────────────────────────────────────────────────────────────
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 10);

  // ── Pagination ────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ── UI ────────────────────────────────────────────────────────────────
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // ── Order ─────────────────────────────────────────────────────────────
  static const double taxRate = 0.0; // 0% – adjust per locale
  static const String currencySymbol = '₱';
  static const String currencyCode = 'PHP';

  // ── Tables ────────────────────────────────────────────────────────────
  static const int defaultTableCapacity = 4;

  // ── Inventory ─────────────────────────────────────────────────────────
  static const int safetyLevel = 10; // low-stock safety threshold
}
