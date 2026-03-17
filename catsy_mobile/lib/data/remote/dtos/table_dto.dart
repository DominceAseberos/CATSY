import 'package:json_annotation/json_annotation.dart';

part 'table_dto.g.dart';

@JsonSerializable()
class TableDto {
  final String id;
  final String label;
  final int capacity;
  final String status;
  @JsonKey(name: 'current_order_id')
  final String? currentOrderId;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const TableDto({
    required this.id,
    required this.label,
    required this.capacity,
    required this.status,
    this.currentOrderId,
    this.updatedAt,
  });

  factory TableDto.fromJson(Map<String, dynamic> json) =>
      _$TableDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TableDtoToJson(this);
}
