import 'package:drift/native.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';

/// Creates a fresh in-memory [AppDatabase] for each test.
///
/// Usage:
/// ```dart
/// late AppDatabase db;
/// setUp(() { db = createTestDatabase(); });
/// tearDown(() => db.close());
/// ```
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}
