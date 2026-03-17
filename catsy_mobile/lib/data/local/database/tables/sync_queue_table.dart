import 'package:drift/drift.dart';

class SyncQueueTable extends Table {
  TextColumn get id => text()();
  TextColumn get targetTable => text()();
  TextColumn get entityId => text()();
  TextColumn get action => text()(); // INSERT, UPDATE, DELETE
  TextColumn get payload => text()(); // JSON string
  TextColumn get status => text()(); // pending, synced, failed
  IntColumn get priority =>
      integer().withDefault(const Constant(0))(); // 0=normal, 1=high
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttempt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
