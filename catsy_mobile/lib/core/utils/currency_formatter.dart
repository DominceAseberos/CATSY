import 'package:intl/intl.dart';
import '../../config/app_constants.dart';

/// Currency formatting utilities for PH Peso (₱).
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  /// Format a double as ₱1,234.56
  static String format(double amount) => _formatter.format(amount);

  /// Parse a formatted string back to double (strips symbol/commas).
  static double parse(String formatted) {
    final cleaned = formatted
        .replaceAll(AppConstants.currencySymbol, '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
}
