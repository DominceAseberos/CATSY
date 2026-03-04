// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableDto _$TableDtoFromJson(Map<String, dynamic> json) => TableDto(
  id: json['id'] as String,
  label: json['label'] as String,
  capacity: (json['capacity'] as num).toInt(),
  status: json['status'] as String,
  currentOrderId: json['current_order_id'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$TableDtoToJson(TableDto instance) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'capacity': instance.capacity,
  'status': instance.status,
  'current_order_id': instance.currentOrderId,
  'updated_at': instance.updatedAt,
};
