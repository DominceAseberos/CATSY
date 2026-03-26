import 'package:equatable/equatable.dart';
import 'package:catsy_pos/domain/entities/addon.dart';

/// A single line item within an order.
class OrderItem extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final List<Addon> addons;
  final String? specialInstructions;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    this.addons = const [],
    this.specialInstructions,
  });

  @override
  List<Object?> get props => [id, productId, quantity, totalPrice];
}
