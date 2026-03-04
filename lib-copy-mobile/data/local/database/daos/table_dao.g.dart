// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_dao.dart';

// ignore_for_file: type=lint
mixin _$TableDaoMixin on DatabaseAccessor<AppDatabase> {
  $CafeTablesTableTable get cafeTablesTable => attachedDatabase.cafeTablesTable;
  TableDaoManager get managers => TableDaoManager(this);
}

class TableDaoManager {
  final _$TableDaoMixin _db;
  TableDaoManager(this._db);
  $$CafeTablesTableTableTableManager get cafeTablesTable =>
      $$CafeTablesTableTableTableManager(
        _db.attachedDatabase,
        _db.cafeTablesTable,
      );
}
