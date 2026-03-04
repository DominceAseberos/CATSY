import 'package:drift/drift.dart';

class LoyaltyStampsTable extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get orderId => text()();
  TextColumn get staffId => text()();
  IntColumn get stampsAdded => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
