// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerDto _$CustomerDtoFromJson(Map<String, dynamic> json) => CustomerDto(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  qrCode: json['qr_code'] as String?,
  totalStamps: (json['total_stamps'] as num).toInt(),
  rewardsRedeemed: (json['rewards_redeemed'] as num).toInt(),
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$CustomerDtoToJson(CustomerDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'qr_code': instance.qrCode,
      'total_stamps': instance.totalStamps,
      'rewards_redeemed': instance.rewardsRedeemed,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
