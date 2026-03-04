import 'package:freezed_annotation/freezed_annotation.dart';
import '../entities/cart_item.dart';
import '../enums/order_type.dart';
import '../enums/payment_status.dart';
import '../enums/payment_method.dart';

part 'cart_state.freezed.dart';

@freezed
abstract class CartState with _$CartState {
  const factory CartState({
    @Default([]) List<CartItem> items,
    String? customerId,
    String? tableId,
    @Default(OrderType.dineIn) OrderType orderType,
    @Default(PaymentStatus.pending) PaymentStatus paymentStatus,
    PaymentMethod? paymentMethod,
    String? notes,
  }) = _CartState;

  const CartState._();

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);

  // Tax logic can be refined later, assuming flat or none for now
  double get tax => 0; // Placeholder

  double get total => subtotal + tax;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}
