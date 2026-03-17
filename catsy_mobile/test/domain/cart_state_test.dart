import 'package:flutter_test/flutter_test.dart';
import 'package:catsy_pos/domain/entities/product.dart';
import 'package:catsy_pos/domain/entities/addon.dart';
import 'package:catsy_pos/domain/entities/cart_item.dart';
import 'package:catsy_pos/domain/models/cart_state.dart';

void main() {
  group('CartState', () {
    test('empty cart has zero subtotal, total, and totalItems', () {
      const cart = CartState();

      expect(cart.subtotal, 0.0);
      expect(cart.total, 0.0);
      expect(cart.totalItems, 0);
      expect(cart.items, isEmpty);
    });

    test('single item without addons calculates correct subtotal', () {
      final product = Product(
        id: 'p1',
        name: 'Latte',
        price: 150.0,
        categoryId: 'cat-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final cart = CartState(
        items: [CartItem(id: 'ci-1', product: product, quantity: 2)],
      );

      expect(cart.subtotal, 300.0); // 150 * 2
      expect(cart.totalItems, 2);
    });

    test('multiple items with addons calculates correct subtotal', () {
      final now = DateTime.now();
      final latte = Product(
        id: 'p1',
        name: 'Latte',
        price: 150.0,
        categoryId: 'cat-1',
        createdAt: now,
        updatedAt: now,
      );
      final cappuccino = Product(
        id: 'p2',
        name: 'Cappuccino',
        price: 180.0,
        categoryId: 'cat-1',
        createdAt: now,
        updatedAt: now,
      );

      const extraShot = Addon(id: 'a1', name: 'Extra Shot', price: 30.0);
      const whippedCream = Addon(id: 'a2', name: 'Whipped Cream', price: 20.0);

      final cart = CartState(
        items: [
          CartItem(
            id: 'ci-1',
            product: latte,
            quantity: 2,
            addons: [extraShot],
          ),
          CartItem(
            id: 'ci-2',
            product: cappuccino,
            quantity: 1,
            addons: [extraShot, whippedCream],
          ),
        ],
      );

      // Latte: (150 + 30) * 2 = 360
      // Cappuccino: (180 + 30 + 20) * 1 = 230
      expect(cart.subtotal, 590.0);
      expect(cart.totalItems, 3);
    });

    test('tax returns 0 (current implementation)', () {
      const cart = CartState();
      expect(cart.tax, 0.0);
    });

    test('total equals subtotal when tax is zero', () {
      final now = DateTime.now();
      final product = Product(
        id: 'p1',
        name: 'Latte',
        price: 150.0,
        categoryId: 'cat-1',
        createdAt: now,
        updatedAt: now,
      );

      final cart = CartState(
        items: [CartItem(id: 'ci-1', product: product, quantity: 1)],
      );

      expect(cart.total, cart.subtotal);
      expect(cart.total, 150.0);
    });
  });
}
