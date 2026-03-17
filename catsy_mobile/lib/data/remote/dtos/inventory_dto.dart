import 'package:json_annotation/json_annotation.dart';

part 'inventory_dto.g.dart';

@JsonSerializable()
class InventoryDto {
  final String id;
  @JsonKey(name: 'product_id')
  final String productId;
  @JsonKey(name: 'product_name')
  final String productName;
  @JsonKey(name: 'current_stock')
  final int currentStock;
  @JsonKey(name: 'min_stock')
  final int minStock;
  final String unit;
  @JsonKey(name: 'last_restocked')
  final String lastRestocked;

  const InventoryDto({
    required this.id,
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.minStock,
    required this.unit,
    required this.lastRestocked,
  });

  factory InventoryDto.fromJson(Map<String, dynamic> json) =>
      _$InventoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryDtoToJson(this);
}
