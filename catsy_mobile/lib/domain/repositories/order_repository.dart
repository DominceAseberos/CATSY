import 'package:catsy_pos/domain/entities/order.dart';
import 'package:catsy_pos/domain/models/cart_state.dart';
import 'package:catsy_pos/domain/models/payment_details.dart';

abstract class OrderRepository {
  /// Create a new order from cart state and payment details.
  /// This performs a transactional write: Order -> Items -> Stock -> Transaction -> Receipt.
  Future<Order> createOrder(CartState cart, PaymentDetails payment);

  /// Watch active orders (pending, preparing).
  Stream<List<Order>> watchActiveOrders();
}
