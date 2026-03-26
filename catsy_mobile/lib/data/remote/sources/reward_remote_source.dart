import 'package:catsy_pos/core/network/api_client.dart';
import 'package:catsy_pos/data/remote/dtos/reward_dto.dart';

class RewardRemoteSource {
  final ApiClient _api;

  RewardRemoteSource(this._api);

  Future<List<RewardDto>> fetchAllRewards() async {
    final data = await _api.get('/loyalty/status') as Map<String, dynamic>;
    final rewards = data['rewards'] as List<dynamic>? ?? [];
    return rewards
        .map((e) => RewardDto.fromJson(_mapReward(e as Map<String, dynamic>)))
        .toList();
  }

  Future<List<RewardDto>> fetchRewardsSince(DateTime since) async {
    return fetchAllRewards();
  }

  Future<RewardDto> createReward(Map<String, dynamic> body) async {
    final data =
        await _api.post('/loyalty/claim', body) as Map<String, dynamic>;
    return RewardDto.fromJson(_mapReward(data));
  }

  Future<RewardDto> redeemReward(String id, Map<String, dynamic> body) async {
    final data =
        await _api.post('/loyalty/redeem', body)
            as Map<String, dynamic>;
    return RewardDto.fromJson(_mapReward(data));
  }

  Map<String, dynamic> _mapReward(Map<String, dynamic> api) {
    return {
      'id': api['id']?.toString(),
      'customer_id': api['customer_id']?.toString(),
      'reward_item': api['reward_item'] ?? api['item_name'],
      'coupon_code': api['coupon_code'],
      'status': api['status'] ?? 'active',
      'claimed_at': api['claimed_at'] ?? api['created_at'],
      'created_at': api['created_at'],
      'updated_at': api['updated_at'],
    };
  }
}
