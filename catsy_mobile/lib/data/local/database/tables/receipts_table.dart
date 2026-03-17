import 'package:drift/drift.dart';

class ReceiptsTable extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get receiptNumber => text()();
  TextColumn get content => text()();
  DateTimeColumn get generatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
