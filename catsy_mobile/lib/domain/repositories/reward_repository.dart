import 'package:dartz/dartz.dart';
import 'package:catsy_pos/core/error/failures.dart';
import 'package:catsy_pos/domain/entities/reward.dart';
import 'package:catsy_pos/domain/models/reward_result.dart';

/// Abstract contract for reward operations.
abstract class RewardRepository {
  Future<Either<Failure, List<Reward>>> getRewards();
  Future<Either<Failure, Reward>> getRewardById(String id);
  Future<Either<Failure, void>> claimReward(String customerId, String rewardId);
  Future<Either<Failure, void>> syncRewards();

  /// Phase 9 — Validate a reward code and mark it as claimed.
  ///
  /// Returns a [RewardResult] that the UI can switch over exhaustively.
  Future<RewardResult> validateAndClaimReward(String code, String staffId);
}
