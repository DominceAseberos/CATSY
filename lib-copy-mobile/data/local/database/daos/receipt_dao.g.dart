// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_dao.dart';

// ignore_for_file: type=lint
mixin _$ReceiptDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReceiptsTableTable get receiptsTable => attachedDatabase.receiptsTable;
  ReceiptDaoManager get managers => ReceiptDaoManager(this);
}

class ReceiptDaoManager {
  final _$ReceiptDaoMixin _db;
  ReceiptDaoManager(this._db);
  $$ReceiptsTableTableTableManager get receiptsTable =>
      $$ReceiptsTableTableTableManager(_db.attachedDatabase, _db.receiptsTable);
}
