import 'package:drift/drift.dart';

class InventoryTable extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  IntColumn get currentStock => integer()();
  IntColumn get minStock => integer().withDefault(const Constant(10))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  DateTimeColumn get lastRestocked => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
