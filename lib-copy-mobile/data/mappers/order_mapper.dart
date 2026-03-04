import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/enums/order_type.dart';
import '../../domain/enums/payment_method.dart';
import '../../domain/enums/payment_status.dart';
import '../remote/dtos/order_dto.dart';

class OrderMapper {
  static Order fromDto(OrderDto dto) => Order(
    id: dto.id,
    tableId: dto.tableId,
    staffId: dto.staffId,
    customerId: dto.customerId,
    orderType: OrderType.values.firstWhere(
      (e) => e.name == dto.orderType,
      orElse: () => OrderType.dineIn,
    ),
    status: OrderStatus.values.firstWhere(
      (e) => e.name == dto.status,
      orElse: () => OrderStatus.pending,
    ),
    paymentStatus: PaymentStatus.values.firstWhere(
      (e) => e.name == dto.paymentStatus,
      orElse: () => PaymentStatus.pending,
    ),
    paymentMethod: dto.paymentMethod != null
        ? PaymentMethod.values.firstWhere(
            (e) => e.name == dto.paymentMethod,
            orElse: () => PaymentMethod.cash,
          )
        : null,
    items: dto.items.map(_itemFromDto).toList(),
    subtotal: dto.subtotal,
    tax: dto.tax,
    discount: dto.discount,
    total: dto.total,
    notes: dto.notes,
    createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
    updatedAt: DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
  );

  static OrderItem _itemFromDto(OrderItemDto dto) => OrderItem(
    id: dto.id,
    orderId: dto.orderId,
    productId: dto.productId,
    productName: dto.productName,
    quantity: dto.quantity,
    unitPrice: dto.unitPrice,
    totalPrice: dto.totalPrice,
  );

  static OrderDto toDto(Order entity) => OrderDto(
    id: entity.id,
    tableId: entity.tableId,
    staffId: entity.staffId,
    customerId: entity.customerId,
    orderType: entity.orderType.name,
    status: entity.status.name,
    paymentStatus: entity.paymentStatus.name,
    paymentMethod: entity.paymentMethod?.name,
    items: entity.items
        .map(
          (i) => OrderItemDto(
            id: i.id,
            orderId: i.orderId,
            productId: i.productId,
            productName: i.productName,
            quantity: i.quantity,
            unitPrice: i.unitPrice,
            totalPrice: i.totalPrice,
          ),
        )
        .toList(),
    subtotal: entity.subtotal,
    tax: entity.tax,
    discount: entity.discount,
    total: entity.total,
    notes: entity.notes,
    createdAt: entity.createdAt.toIso8601String(),
    updatedAt: entity.updatedAt.toIso8601String(),
  );
}
