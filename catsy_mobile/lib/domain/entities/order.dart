import 'package:equatable/equatable.dart';
import '../enums/order_type.dart';
import '../enums/order_status.dart';
import '../enums/payment_status.dart';
import '../enums/payment_method.dart';
import 'order_item.dart';

/// Order entity – represents a customer's order.
class Order extends Equatable {
  final String id;
  final String? tableId;
  final String staffId;
  final String? customerId;
  final OrderType orderType;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    this.tableId,
    required this.staffId,
    this.customerId,
    required this.orderType,
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMethod,
    this.items = const [],
    this.subtotal = 0,
    this.tax = 0,
    this.discount = 0,
    this.total = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, status, paymentStatus, total];
}
