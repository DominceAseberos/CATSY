// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderDto _$OrderDtoFromJson(Map<String, dynamic> json) => OrderDto(
  id: json['id'] as String,
  tableId: json['table_id'] as String?,
  staffId: json['staff_id'] as String,
  customerId: json['customer_id'] as String?,
  orderType: json['order_type'] as String,
  status: json['status'] as String,
  paymentStatus: json['payment_status'] as String,
  paymentMethod: json['payment_method'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItemDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  subtotal: (json['subtotal'] as num).toDouble(),
  tax: (json['tax'] as num).toDouble(),
  discount: (json['discount'] as num).toDouble(),
  total: (json['total'] as num).toDouble(),
  notes: json['notes'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$OrderDtoToJson(OrderDto instance) => <String, dynamic>{
  'id': instance.id,
  'table_id': instance.tableId,
  'staff_id': instance.staffId,
  'customer_id': instance.customerId,
  'order_type': instance.orderType,
  'status': instance.status,
  'payment_status': instance.paymentStatus,
  'payment_method': instance.paymentMethod,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'subtotal': instance.subtotal,
  'tax': instance.tax,
  'discount': instance.discount,
  'total': instance.total,
  'notes': instance.notes,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

OrderItemDto _$OrderItemDtoFromJson(Map<String, dynamic> json) => OrderItemDto(
  id: json['id'] as String,
  orderId: json['order_id'] as String,
  productId: json['product_id'] as String,
  productName: json['product_name'] as String,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: (json['unit_price'] as num).toDouble(),
  totalPrice: (json['total_price'] as num).toDouble(),
);

Map<String, dynamic> _$OrderItemDtoToJson(OrderItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'product_id': instance.productId,
      'product_name': instance.productName,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'total_price': instance.totalPrice,
    };
