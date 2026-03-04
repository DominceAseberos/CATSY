import 'package:json_annotation/json_annotation.dart';

part 'order_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class OrderDto {
  final String id;
  @JsonKey(name: 'table_id')
  final String? tableId;
  @JsonKey(name: 'staff_id')
  final String staffId;
  @JsonKey(name: 'customer_id')
  final String? customerId;
  @JsonKey(name: 'order_type')
  final String orderType;
  final String status;
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  final List<OrderItemDto> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String? notes;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const OrderDto({
    required this.id,
    this.tableId,
    required this.staffId,
    this.customerId,
    required this.orderType,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.items = const [],
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDtoToJson(this);
}

@JsonSerializable()
class OrderItemDto {
  final String id;
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'product_id')
  final String productId;
  @JsonKey(name: 'product_name')
  final String productName;
  final int quantity;
  @JsonKey(name: 'unit_price')
  final double unitPrice;
  @JsonKey(name: 'total_price')
  final double totalPrice;

  const OrderItemDto({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItemDto.fromJson(Map<String, dynamic> json) =>
      _$OrderItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemDtoToJson(this);
}
