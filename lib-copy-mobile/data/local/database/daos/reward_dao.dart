import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/rewards_table.dart';

part 'reward_dao.g.dart';

@DriftAccessor(tables: [RewardsTable])
class RewardDao extends DatabaseAccessor<AppDatabase> with _$RewardDaoMixin {
  RewardDao(super.db);

  // ── Read ─────────────────────────────────────────────────────────────
  Future<List<RewardsTableData>> getAllRewards() => select(rewardsTable).get();

  Future<RewardsTableData?> getRewardById(String id) =>
      (select(rewardsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<RewardsTableData>> getActiveRewards() =>
      (select(rewardsTable)..where((t) => t.isActive.equals(true))).get();

  /// Phase 9 — Look up a reward by its claim code.
  Future<RewardsTableData?> getRewardByCode(String code) => (select(
    rewardsTable,
  )..where((t) => t.code.equals(code))).getSingleOrNull();

  // ── Write ───────────────────────────────────────────────────────────
  Future<void> insertReward(RewardsTableCompanion reward) =>
      into(rewardsTable).insertOnConflictUpdate(reward);

  Future<void> markRewardInactive(String id) =>
      (update(rewardsTable)..where((t) => t.id.equals(id))).write(
        const RewardsTableCompanion(isActive: Value(false)),
      );

  /// Phase 9 — Mark a reward as claimed.
  Future<void> markRewardClaimed(String id, String staffId) =>
      (update(rewardsTable)..where((t) => t.id.equals(id))).write(
        RewardsTableCompanion(
          isClaimed: const Value(true),
          claimedByStaffId: Value(staffId),
          claimedAt: Value(DateTime.now()),
        ),
      );
}
