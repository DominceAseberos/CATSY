import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:catsy_pos/app.dart';
import 'package:catsy_pos/core/error/error_reporting_service.dart';
import 'package:catsy_pos/core/utils/logger.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/sync/sync_engine.dart';

Future<void> main() async {
  ErrorReportingService? globalErrorReporter;

  unawaited(runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // ── Local database (Drift) ──────────────────────────────────────────
    final database = AppDatabase();
    AppLogger.i('Drift database opened');

    // ── Run app with Riverpod ───────────────────────────────────────────
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );

    globalErrorReporter = container.read(errorReportingServiceProvider);

    FlutterError.onError = (FlutterErrorDetails details) {
      globalErrorReporter?.reportFlutterError(details);
    };

    // ── Start Sync Engine after DI is ready ────────────────────────────
    // Lazy-start in a post-frame callback so the app is visible first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        container.read(syncEngineProvider).start();
        AppLogger.i('SyncEngine started');
      } catch (e) {
        AppLogger.e('SyncEngine start failed: $e');
      }
    });

    runApp(
      UncontrolledProviderScope(container: container, child: const CatsyPosApp()),
    );
  }, (Object error, StackTrace stackTrace) {
    // ── Global Error Boundary ───────────────────────────────────────────
    if (globalErrorReporter != null) {
      globalErrorReporter!.reportError(error, stackTrace, reason: 'runZonedGuarded uncaught error');
    } else {
      AppLogger.f('Unhandled root error before DI: $error', error: error, stackTrace: stackTrace);
    }
  }));
}
