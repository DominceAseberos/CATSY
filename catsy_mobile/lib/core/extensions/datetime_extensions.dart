/// DateTime extensions for common operations.
extension DateTimeExt on DateTime {
  /// Start of the current day (midnight).
  DateTime get startOfDay => DateTime(year, month, day);

  /// End of the current day (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Whether this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Whether this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Whether this date is in the future.
  bool get isFuture => isAfter(DateTime.now());

  /// Whether this date is in the past.
  bool get isPast => isBefore(DateTime.now());
}
