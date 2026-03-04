import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/reward.dart';
import '../models/reward_result.dart';

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
