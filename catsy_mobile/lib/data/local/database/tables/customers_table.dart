import 'package:drift/drift.dart';

class CustomersTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get qrCode => text().nullable()();
  IntColumn get totalStamps => integer().withDefault(const Constant(0))();
  IntColumn get rewardsRedeemed => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
