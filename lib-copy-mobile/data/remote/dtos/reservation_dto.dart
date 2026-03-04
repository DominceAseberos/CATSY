import 'package:json_annotation/json_annotation.dart';

part 'reservation_dto.g.dart';

@JsonSerializable()
class ReservationDto {
  final String id;
  @JsonKey(name: 'customer_name')
  final String customerName;
  @JsonKey(name: 'customer_phone')
  final String? customerPhone;
  @JsonKey(name: 'table_id')
  final String? tableId;
  @JsonKey(name: 'party_size')
  final int partySize;
  @JsonKey(name: 'reservation_date')
  final String reservationDate;
  @JsonKey(name: 'reservation_time')
  final String reservationTime;
  final String status;
  final String? notes;
  @JsonKey(name: 'handled_by')
  final String? handledBy;
  @JsonKey(name: 'rejection_reason')
  final String? rejectionReason;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const ReservationDto({
    required this.id,
    required this.customerName,
    this.customerPhone,
    this.tableId,
    required this.partySize,
    required this.reservationDate,
    required this.reservationTime,
    required this.status,
    this.notes,
    this.handledBy,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReservationDto.fromJson(Map<String, dynamic> json) =>
      _$ReservationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReservationDtoToJson(this);
}
