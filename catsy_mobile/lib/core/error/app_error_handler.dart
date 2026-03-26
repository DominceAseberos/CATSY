import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:catsy_pos/core/error/failures.dart';

/// AppErrorHandler converts complex technical exceptions into user-friendly messages.
class AppErrorHandler {
  AppErrorHandler._();

  /// Converts any exception to a user-friendly string.
  static String getMessage(dynamic error) {
    if (error is ServerFailure) {
      return error.message; // Already user-friendly from ApiClient
    }

    if (error is SocketException) {
      return 'No internet connection. Please verify your network and try again.';
    }

    if (error is TimeoutException) {
      return 'The request timed out. Please try again later.';
    }

    if (error is FormatException) {
      return 'We received unexpected data from the server. Please try again.';
    }

    if (error is PlatformException) {
      return 'A system error occurred: ${error.message ?? 'Unknown Platform Error'}';
    }

    // Default fallback
    final msg = error.toString();
    if (msg.contains('Failed host lookup')) {
      return 'Could not connect to the server. Please check your internet connection.';
    }

    // Fallback for completely unknown errors
    return 'An unexpected error occurred. Please try again later.';
  }
}
