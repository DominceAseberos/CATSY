// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RewardDto _$RewardDtoFromJson(Map<String, dynamic> json) => RewardDto(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  stampsRequired: (json['stamps_required'] as num).toInt(),
  isActive: json['is_active'] as bool,
  code: json['code'] as String?,
  customerId: json['customer_id'] as String?,
  isClaimed: json['is_claimed'] as bool? ?? false,
  claimedByStaffId: json['claimed_by_staff_id'] as String?,
  claimedAt: json['claimed_at'] as String?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$RewardDtoToJson(RewardDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'stamps_required': instance.stampsRequired,
  'is_active': instance.isActive,
  'code': instance.code,
  'customer_id': instance.customerId,
  'is_claimed': instance.isClaimed,
  'claimed_by_staff_id': instance.claimedByStaffId,
  'claimed_at': instance.claimedAt,
  'created_at': instance.createdAt,
};
