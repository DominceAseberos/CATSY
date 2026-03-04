// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dao.dart';

// ignore_for_file: type=lint
mixin _$AuthDaoMixin on DatabaseAccessor<AppDatabase> {
  $StaffTableTable get staffTable => attachedDatabase.staffTable;
  AuthDaoManager get managers => AuthDaoManager(this);
}

class AuthDaoManager {
  final _$AuthDaoMixin _db;
  AuthDaoManager(this._db);
  $$StaffTableTableTableManager get staffTable =>
      $$StaffTableTableTableManager(_db.attachedDatabase, _db.staffTable);
}
