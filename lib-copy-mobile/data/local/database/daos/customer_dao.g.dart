// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_dao.dart';

// ignore_for_file: type=lint
mixin _$CustomerDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomersTableTable get customersTable => attachedDatabase.customersTable;
  $LoyaltyStampsTableTable get loyaltyStampsTable =>
      attachedDatabase.loyaltyStampsTable;
  CustomerDaoManager get managers => CustomerDaoManager(this);
}

class CustomerDaoManager {
  final _$CustomerDaoMixin _db;
  CustomerDaoManager(this._db);
  $$CustomersTableTableTableManager get customersTable =>
      $$CustomersTableTableTableManager(
        _db.attachedDatabase,
        _db.customersTable,
      );
  $$LoyaltyStampsTableTableTableManager get loyaltyStampsTable =>
      $$LoyaltyStampsTableTableTableManager(
        _db.attachedDatabase,
        _db.loyaltyStampsTable,
      );
}
