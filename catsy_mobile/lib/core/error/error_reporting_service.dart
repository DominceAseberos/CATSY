import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';

/// Abstract service for reporting unhandled errors and crashes to a remote service.
/// This acts as a boundary to swap between Crashlytics, Sentry, or simple logging.
abstract class ErrorReportingService {
  /// Report a framework-level error (e.g., from FlutterError.onError).
  void reportFlutterError(FlutterErrorDetails details);

  /// Report any arbitrary Dart error and its stack trace.
  void reportError(dynamic error, StackTrace stackTrace, {dynamic reason});
}

/// A concrete implementation that logs errors to the console using [AppLogger].
/// Suitable for development, or as a fallback before Crashlytics is integrated.
class ConsoleErrorReporter implements ErrorReportingService {
  @override
  void reportFlutterError(FlutterErrorDetails details) {
    AppLogger.f('[CrashDump] Flutter Framework Error: ${details.exceptionAsString()}', error: details.exception, stackTrace: details.stack);
  }

  @override
  void reportError(dynamic error, StackTrace stackTrace, {dynamic reason}) {
    AppLogger.f('[CrashDump] Dart Error: $error\nReason: $reason', error: error, stackTrace: stackTrace);
  }
}

// ── Providers ──────────────────────────────────────────────────────────

/// Provides the active error reporting service.
final errorReportingServiceProvider = Provider<ErrorReportingService>((ref) {
  // In the future, you could return a CrashlyticsErrorReporter based on environment.
  return ConsoleErrorReporter();
});
