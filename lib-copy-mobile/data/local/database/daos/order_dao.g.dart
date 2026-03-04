// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dao.dart';

// ignore_for_file: type=lint
mixin _$OrderDaoMixin on DatabaseAccessor<AppDatabase> {
  $OrdersTableTable get ordersTable => attachedDatabase.ordersTable;
  $OrderItemsTableTable get orderItemsTable => attachedDatabase.orderItemsTable;
  $OrderItemAddonsTableTable get orderItemAddonsTable =>
      attachedDatabase.orderItemAddonsTable;
  OrderDaoManager get managers => OrderDaoManager(this);
}

class OrderDaoManager {
  final _$OrderDaoMixin _db;
  OrderDaoManager(this._db);
  $$OrdersTableTableTableManager get ordersTable =>
      $$OrdersTableTableTableManager(_db.attachedDatabase, _db.ordersTable);
  $$OrderItemsTableTableTableManager get orderItemsTable =>
      $$OrderItemsTableTableTableManager(
        _db.attachedDatabase,
        _db.orderItemsTable,
      );
  $$OrderItemAddonsTableTableTableManager get orderItemAddonsTable =>
      $$OrderItemAddonsTableTableTableManager(
        _db.attachedDatabase,
        _db.orderItemAddonsTable,
      );
}
