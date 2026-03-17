import 'package:drift/drift.dart';

/// Records every conflict resolution decision for audit and debugging.
class SyncConflictLogTable extends Table {
  TextColumn get id => text()();
  TextColumn get targetTable => text()();
  TextColumn get entityId => text()();
  TextColumn get localJson => text()(); // local record JSON at conflict time
  TextColumn get remoteJson => text()(); // remote record JSON at conflict time
  TextColumn get winner =>
      text()(); // 'local' | 'remote' | 'merged' | 'remote_delete'
  DateTimeColumn get resolvedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
