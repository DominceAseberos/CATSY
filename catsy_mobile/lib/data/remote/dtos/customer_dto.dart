import 'package:json_annotation/json_annotation.dart';

part 'customer_dto.g.dart';

@JsonSerializable()
class CustomerDto {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  @JsonKey(name: 'qr_code')
  final String? qrCode;
  @JsonKey(name: 'total_stamps')
  final int totalStamps;
  @JsonKey(name: 'rewards_redeemed')
  final int rewardsRedeemed;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const CustomerDto({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.qrCode,
    required this.totalStamps,
    required this.rewardsRedeemed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerDto.fromJson(Map<String, dynamic> json) =>
      _$CustomerDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDtoToJson(this);
}
