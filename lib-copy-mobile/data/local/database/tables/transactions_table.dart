import 'package:drift/drift.dart';

class TransactionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get paymentMethod => text()();
  RealColumn get amount => real()();
  RealColumn get change => real().nullable()();
  DateTimeColumn get transactedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
