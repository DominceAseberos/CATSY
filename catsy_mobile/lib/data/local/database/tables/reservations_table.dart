import 'package:drift/drift.dart';

class ReservationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get customerName => text()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get tableId => text().nullable()();
  IntColumn get partySize => integer()();
  DateTimeColumn get reservationDate => dateTime()();
  DateTimeColumn get reservationTime => dateTime()();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get handledBy => text().nullable()();
  TextColumn get rejectionReason => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
