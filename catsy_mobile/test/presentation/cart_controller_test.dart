import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catsy_pos/domain/entities/product.dart';
import 'package:catsy_pos/domain/entities/addon.dart';
import 'package:catsy_pos/domain/enums/order_type.dart';
import 'package:catsy_pos/domain/enums/payment_method.dart';
import 'package:catsy_pos/domain/models/cart_state.dart';
import 'package:catsy_pos/presentation/order/providers/cart_controller.dart';

void main() {
  late ProviderContainer container;
  final now = DateTime.now();

  final testProduct = Product(
    id: 'p1',
    name: 'Latte',
    price: 150.0,
    categoryId: 'cat-1',
    createdAt: now,
    updatedAt: now,
  );

  final testProduct2 = Product(
    id: 'p2',
    name: 'Cappuccino',
    price: 180.0,
    categoryId: 'cat-1',
    createdAt: now,
    updatedAt: now,
  );

  const testAddon = Addon(id: 'a1', name: 'Extra Shot', price: 30.0);

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  CartState readState() => container.read(cartProvider);
  CartController readNotifier() => container.read(cartProvider.notifier);

  group('CartController', () {
    test('initial state is an empty cart', () {
      final state = readState();
      expect(state.items, isEmpty);
      expect(state.subtotal, 0.0);
    });

    group('addItem', () {
      test('adds item to cart', () {
        readNotifier().addItem(product: testProduct);

        final state = readState();
        expect(state.items.length, 1);
        expect(state.items.first.product.name, 'Latte');
        expect(state.items.first.quantity, 1);
      });

      test('adds item with quantity and addons', () {
        readNotifier().addItem(
          product: testProduct,
          quantity: 3,
          addons: [testAddon],
        );

        final state = readState();
        expect(state.items.length, 1);
        expect(state.items.first.quantity, 3);
        expect(state.items.first.addons.length, 1);
        // (150 + 30) * 3 = 540
        expect(state.subtotal, 540.0);
      });

      test('adds multiple distinct items', () {
        readNotifier().addItem(product: testProduct);
        readNotifier().addItem(product: testProduct2);

        final state = readState();
        expect(state.items.length, 2);
      });
    });

    group('removeItem', () {
      test('removes item by ID', () {
        readNotifier().addItem(product: testProduct);
        final itemId = readState().items.first.id;

        readNotifier().removeItem(itemId);

        expect(readState().items, isEmpty);
      });

      test('does not affect other items', () {
        readNotifier().addItem(product: testProduct);
        readNotifier().addItem(product: testProduct2);
        final firstId = readState().items.first.id;

        readNotifier().removeItem(firstId);

        expect(readState().items.length, 1);
        expect(readState().items.first.product.name, 'Cappuccino');
      });
    });

    group('updateQuantity', () {
      test('updates quantity of an item', () {
        readNotifier().addItem(product: testProduct);
        final itemId = readState().items.first.id;

        readNotifier().updateQuantity(itemId, 5);

        expect(readState().items.first.quantity, 5);
      });

      test('removes item when quantity set to 0', () {
        readNotifier().addItem(product: testProduct);
        final itemId = readState().items.first.id;

        readNotifier().updateQuantity(itemId, 0);

        expect(readState().items, isEmpty);
      });

      test('removes item when quantity is negative', () {
        readNotifier().addItem(product: testProduct);
        final itemId = readState().items.first.id;

        readNotifier().updateQuantity(itemId, -1);

        expect(readState().items, isEmpty);
      });
    });

    group('clearCart', () {
      test('resets cart to empty state', () {
        readNotifier().addItem(product: testProduct);
        readNotifier().addItem(product: testProduct2);
        readNotifier().setOrderType(OrderType.takeOut);
        readNotifier().setTableId('table-1');

        readNotifier().clearCart();

        final state = readState();
        expect(state.items, isEmpty);
        expect(state.orderType, OrderType.dineIn);
        expect(state.tableId, isNull);
      });
    });

    group('setOrderType', () {
      test('updates order type', () {
        readNotifier().setOrderType(OrderType.takeOut);
        expect(readState().orderType, OrderType.takeOut);
      });
    });

    group('setTableId', () {
      test('sets table ID', () {
        readNotifier().setTableId('table-001');
        expect(readState().tableId, 'table-001');
      });

      test('clears table ID with null', () {
        readNotifier().setTableId('table-001');
        readNotifier().setTableId(null);
        expect(readState().tableId, isNull);
      });
    });

    group('setCustomer', () {
      test('sets customer ID', () {
        readNotifier().setCustomer('cust-001');
        expect(readState().customerId, 'cust-001');
      });
    });

    group('setPaymentMethod', () {
      test('sets payment method', () {
        readNotifier().setPaymentMethod(PaymentMethod.cash);
        expect(readState().paymentMethod, PaymentMethod.cash);
      });
    });
  });
}
