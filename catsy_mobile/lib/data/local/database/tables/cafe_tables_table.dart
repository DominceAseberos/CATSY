import 'package:drift/drift.dart';

class CafeTablesTable extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  IntColumn get capacity => integer().withDefault(const Constant(4))();
  TextColumn get status => text()();
  TextColumn get currentOrderId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
