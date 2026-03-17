import 'package:drift/drift.dart';

class OrderItemAddonsTable extends Table {
  TextColumn get id => text()();
  TextColumn get orderItemId => text()();
  TextColumn get addonId => text()();
  TextColumn get addonName => text()();
  RealColumn get price => real()();

  @override
  Set<Column> get primaryKey => {id};
}
