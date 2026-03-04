// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_dao.dart';

// ignore_for_file: type=lint
mixin _$RewardDaoMixin on DatabaseAccessor<AppDatabase> {
  $RewardsTableTable get rewardsTable => attachedDatabase.rewardsTable;
  RewardDaoManager get managers => RewardDaoManager(this);
}

class RewardDaoManager {
  final _$RewardDaoMixin _db;
  RewardDaoManager(this._db);
  $$RewardsTableTableTableManager get rewardsTable =>
      $$RewardsTableTableTableManager(_db.attachedDatabase, _db.rewardsTable);
}
