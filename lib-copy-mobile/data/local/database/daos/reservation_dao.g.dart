// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_dao.dart';

// ignore_for_file: type=lint
mixin _$ReservationDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReservationsTableTable get reservationsTable =>
      attachedDatabase.reservationsTable;
  ReservationDaoManager get managers => ReservationDaoManager(this);
}

class ReservationDaoManager {
  final _$ReservationDaoMixin _db;
  ReservationDaoManager(this._db);
  $$ReservationsTableTableTableManager get reservationsTable =>
      $$ReservationsTableTableTableManager(
        _db.attachedDatabase,
        _db.reservationsTable,
      );
}
