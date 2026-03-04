// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_dao.dart';

// ignore_for_file: type=lint
mixin _$InventoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $InventoryTableTable get inventoryTable => attachedDatabase.inventoryTable;
  InventoryDaoManager get managers => InventoryDaoManager(this);
}

class InventoryDaoManager {
  final _$InventoryDaoMixin _db;
  InventoryDaoManager(this._db);
  $$InventoryTableTableTableManager get inventoryTable =>
      $$InventoryTableTableTableManager(
        _db.attachedDatabase,
        _db.inventoryTable,
      );
}
