import 'package:logger/logger.dart' as log_pkg;

/// Application-wide logger instance.
///
/// Usage: `AppLogger.d('debug message')`, `AppLogger.e('error', error: e)`.
class AppLogger {
  AppLogger._();

  static final log_pkg.Logger _logger = log_pkg.Logger(
    printer: log_pkg.PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: log_pkg.DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void d(String message) => _logger.d(message);
  static void i(String message) => _logger.i(message);
  static void w(String message) => _logger.w(message);
  static void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
  static void t(String message) => _logger.t(message);
  static void f(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}
