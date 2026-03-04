import 'package:drift/drift.dart';

class OrderItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
  TextColumn get specialInstructions => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
