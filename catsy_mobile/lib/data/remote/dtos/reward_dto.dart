import 'package:json_annotation/json_annotation.dart';

part 'reward_dto.g.dart';

@JsonSerializable()
class RewardDto {
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'stamps_required')
  final int stampsRequired;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final String? code;
  @JsonKey(name: 'customer_id')
  final String? customerId;
  @JsonKey(name: 'is_claimed')
  final bool isClaimed;
  @JsonKey(name: 'claimed_by_staff_id')
  final String? claimedByStaffId;
  @JsonKey(name: 'claimed_at')
  final String? claimedAt;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const RewardDto({
    required this.id,
    required this.name,
    this.description,
    required this.stampsRequired,
    required this.isActive,
    this.code,
    this.customerId,
    this.isClaimed = false,
    this.claimedByStaffId,
    this.claimedAt,
    required this.createdAt,
  });

  factory RewardDto.fromJson(Map<String, dynamic> json) =>
      _$RewardDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RewardDtoToJson(this);
}
