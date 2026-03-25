import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.productPrice * quantity;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final newState = [...state];
      newState[index].quantity++;
      state = newState;
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void decrementItem(String productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (state[index].quantity > 1) {
        final newState = [...state];
        newState[index].quantity--;
        state = newState;
      } else {
        removeItem(productId);
      }
    }
  }

  void clearCache() {
    state = [];
  }

  double get totalAmount => state.fold(0, (sum, item) => sum + item.total);
  int get totalItems => state.fold(0, (sum, item) => sum + item.quantity);
  
  // Count how many items in the cart are eligible for stamps
  int get eligibleStampCount => state.fold(0, (sum, item) => sum + (item.product.isEligible ? item.quantity : 0));
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
