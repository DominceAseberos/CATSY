import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/addon.dart';
import '../../../domain/enums/order_type.dart';
import '../../../domain/enums/payment_method.dart';
import '../../../domain/models/cart_state.dart';

class CartController extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState();
  }

  void addItem({
    required Product product,
    int quantity = 1,
    List<Addon> addons = const [],
    String? notes,
  }) {
    // Check if item already exists with exact same options to merge
    // For simplicity in this phase, we'll just add a new line item mostly,
    // unless exact match is found.
    // Actually, distinct line items are safer for POS (e.g. one coffee with soy, one without).
    // Logic: If exact match (product + addons + notes), update quantity.

    final newItem = CartItem(
      product: product,
      quantity: quantity,
      addons: addons,
      notes: notes,
    );

    state = state.copyWith(items: [...state.items, newItem]);
  }

  void removeItem(String cartItemId) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != cartItemId).toList(),
    );
  }

  void updateQuantity(String cartItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(cartItemId);
      return;
    }

    state = state.copyWith(
      items: state.items.map((item) {
        if (item.id == cartItemId) {
          return item.copyWith(quantity: newQuantity);
        }
        return item;
      }).toList(),
    );
  }

  void setOrderType(OrderType type) {
    state = state.copyWith(orderType: type);
  }

  void setTableId(String? tableId) {
    state = state.copyWith(tableId: tableId);
  }

  void setCustomer(String? customerId) {
    state = state.copyWith(customerId: customerId);
  }

  void setPaymentMethod(PaymentMethod? method) {
    state = state.copyWith(paymentMethod: method);
  }

  void clearCart() {
    state = const CartState();
  }
}

final cartProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);
