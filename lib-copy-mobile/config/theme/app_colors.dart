import 'package:flutter/material.dart';

/// Centralised colour palette for CATSY POS.
class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6C63FF); // Deep violet
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF3F35CC);

  static const Color secondary = Color(0xFFFF6584); // Coral pink
  static const Color secondaryLight = Color(0xFFFF8FA3);
  static const Color secondaryDark = Color(0xFFCC4060);

  static const Color accent = Color(0xFF00D9A6); // Mint green

  // ── Semantic ──────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // ── Neutral ───────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textHint = Color(0xFFBDC3C7);

  static const Color divider = Color(0xFFECECEC);
  static const Color border = Color(0xFFDDDDDD);
  static const Color disabled = Color(0xFFBDBDBD);

  // ── Table Statuses ────────────────────────────────────────────────────
  static const Color tableAvailable = Color(0xFF2ECC71);
  static const Color tableOccupied = Color(0xFFE74C3C);
  static const Color tableReserved = Color(0xFFF39C12);

  // ── Order Statuses ────────────────────────────────────────────────────
  static const Color orderPending = Color(0xFFF39C12);
  static const Color orderConfirmed = Color(0xFF3498DB);
  static const Color orderCompleted = Color(0xFF2ECC71);
  static const Color orderCancelled = Color(0xFFE74C3C);

  // ── Dark Theme ────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF16213E);
  static const Color darkCard = Color(0xFF0F3460);
}
