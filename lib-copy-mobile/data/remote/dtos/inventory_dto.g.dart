// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryDto _$InventoryDtoFromJson(Map<String, dynamic> json) => InventoryDto(
  id: json['id'] as String,
  productId: json['product_id'] as String,
  productName: json['product_name'] as String,
  currentStock: (json['current_stock'] as num).toInt(),
  minStock: (json['min_stock'] as num).toInt(),
  unit: json['unit'] as String,
  lastRestocked: json['last_restocked'] as String,
);

Map<String, dynamic> _$InventoryDtoToJson(InventoryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_id': instance.productId,
      'product_name': instance.productName,
      'current_stock': instance.currentStock,
      'min_stock': instance.minStock,
      'unit': instance.unit,
      'last_restocked': instance.lastRestocked,
    };
