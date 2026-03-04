import 'package:drift/drift.dart';

class SyncQueueTable extends Table {
  TextColumn get id => text()();
  TextColumn get targetTable => text()();
  TextColumn get entityId => text()();
  TextColumn get action => text()(); // INSERT, UPDATE, DELETE
  TextColumn get payload => text()(); // JSON string
  TextColumn get status => text()(); // pending, syncing, synced, failed
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttempt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
