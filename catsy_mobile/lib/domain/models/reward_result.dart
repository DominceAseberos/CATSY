import 'package:catsy_pos/domain/entities/reward.dart';

/// Result type for the [validateAndClaimReward] flow.
///
/// Using a sealed class lets the UI exhaustively switch over all states.
sealed class RewardResult {}

/// The reward was successfully validated and marked as claimed.
class RewardSuccess extends RewardResult {
  final Reward reward;
  RewardSuccess(this.reward);
}

/// The reward code was already claimed previously — prevent double-claiming.
class RewardAlreadyClaimed extends RewardResult {}

/// No reward with this code exists in the local cache.
class RewardInvalidCode extends RewardResult {}

/// Device is offline — server-side validation is impossible.
class RewardNoInternet extends RewardResult {}
