import 'package:drift/drift.dart';

class OrdersTable extends Table {
  TextColumn get id => text()();
  TextColumn get tableId => text().nullable()();
  TextColumn get staffId => text()();
  TextColumn get customerId => text().nullable()();
  TextColumn get orderType => text()(); // dineIn, takeOut
  TextColumn get status => text()(); // pending, confirmed, completed, cancelled
  TextColumn get paymentStatus => text()();
  TextColumn get paymentMethod => text().nullable()();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
