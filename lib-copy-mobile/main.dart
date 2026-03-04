import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/logger.dart';
import 'data/local/database/app_database.dart';
import 'sync/sync_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Load .env ───────────────────────────────────────────────────────
  await dotenv.load(fileName: '.env');
  AppLogger.i('.env loaded');

  // ── Local database (Drift) ──────────────────────────────────────────
  final database = AppDatabase();
  AppLogger.i('Drift database opened');

  // ── Run app with Riverpod ───────────────────────────────────────────
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
  );

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
}
