import 'package:dartz/dartz.dart';
import 'package:catsy_pos/core/error/failures.dart';
import 'package:catsy_pos/core/network/connectivity_service.dart';
import 'package:catsy_pos/domain/entities/reward.dart';
import 'package:catsy_pos/domain/models/reward_result.dart';
import 'package:catsy_pos/domain/repositories/reward_repository.dart';
import 'package:catsy_pos/data/local/database/daos/customer_dao.dart';
import 'package:catsy_pos/data/local/database/daos/reward_dao.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';

/// Phase 9 — Implements local-first reward validation and claiming.
class RewardRepositoryImpl implements RewardRepository {
  final RewardDao _rewardDao;
  final CustomerDao _customerDao;
  final ConnectivityService _connectivity;

  RewardRepositoryImpl({
    required RewardDao rewardDao,
    required CustomerDao customerDao,
    required ConnectivityService connectivity,
  }) : _rewardDao = rewardDao,
       _customerDao = customerDao,
       _connectivity = connectivity;

  // ── Phase 9: Core claim flow ──────────────────────────────────────────

  @override
  Future<RewardResult> validateAndClaimReward(
    String code,
    String staffId,
  ) async {
    // 1. Check local cache first (previously synced rewards).
    final localRow = await _rewardDao.getRewardByCode(code);

    // 2. If found locally and already claimed → reject immediately (no network
    //    needed — this is a definitive local truth).
    if (localRow != null && localRow.isClaimed) {
      return RewardAlreadyClaimed();
    }

    // 3. This feature REQUIRES internet for server-side de-duplication.
    //    The local cache alone cannot prevent cross-device double-claims.
    final isOnline = await _connectivity.isConnected;
    if (!isOnline) {
      return RewardNoInternet();
    }

    // 4. Validate against local cache only (Phase 12 adds remote API call).
    //    If the code has never been synced down → we can't claim it.
    if (localRow == null) {
      return RewardInvalidCode();
    }

    // 5. Mark as claimed locally and reset the customer's stamp count.
    await _rewardDao.markRewardClaimed(localRow.id, staffId);

    if (localRow.customerId != null) {
      await _customerDao.updateStamps(localRow.customerId!, 0);
    }

    return RewardSuccess(_mapToReward(localRow));
  }

  // ── Existing contract methods ─────────────────────────────────────────

  @override
  Future<Either<Failure, List<Reward>>> getRewards() async {
    try {
      final rows = await _rewardDao.getAllRewards();
      return Right(rows.map(_mapToReward).toList());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get rewards: $e'));
    }
  }

  @override
  Future<Either<Failure, Reward>> getRewardById(String id) async {
    try {
      final row = await _rewardDao.getRewardById(id);
      if (row == null) {
        return const Left(CacheFailure(message: 'Reward not found'));
      }
      return Right(_mapToReward(row));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get reward: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> claimReward(
    String customerId,
    String rewardId,
  ) async {
    try {
      await _rewardDao.markRewardInactive(rewardId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to claim reward: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncRewards() async {
    // Phase 12: Remote sync — no-op for now.
    return const Right(null);
  }

  // ── Mapping ──────────────────────────────────────────────────────────

  Reward _mapToReward(RewardsTableData r) => Reward(
    id: r.id,
    name: r.name,
    description: r.description,
    stampsRequired: r.stampsRequired,
    isActive: r.isActive,
    createdAt: r.createdAt,
    code: r.code,
    customerId: r.customerId,
    isClaimed: r.isClaimed,
    claimedByStaffId: r.claimedByStaffId,
    claimedAt: r.claimedAt,
  );
}
