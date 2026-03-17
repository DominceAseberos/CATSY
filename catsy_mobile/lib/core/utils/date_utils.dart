import 'package:intl/intl.dart';

/// Date/time formatting helpers.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy  hh:mm a');
  static final DateFormat _isoFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String toIso(DateTime date) => _isoFormat.format(date);

  /// Returns a human-readable relative string like "2 min ago".
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }
}
