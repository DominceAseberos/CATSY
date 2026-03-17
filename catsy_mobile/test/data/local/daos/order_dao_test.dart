import 'package:flutter_test/flutter_test.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/daos/order_dao.dart';

import '../../../helpers/test_database.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  late AppDatabase db;
  late OrderDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = db.orderDao;
  });

  tearDown(() => db.close());

  group('OrderDao', () {
    group('insertOrder & getOrderById', () {
      test('inserts and retrieves an order', () async {
        await dao.insertOrder(TestFixtures.order());

        final result = await dao.getOrderById('order-001');

        expect(result, isNotNull);
        expect(result!.id, 'order-001');
        expect(result.staffId, 'staff-001');
        expect(result.status, 'pending');
        expect(result.total, 300.0);
      });
    });

    group('generateOrderNumber', () {
      test('generates ORD-YYYYMMDD-001 on first call', () async {
        final number = await dao.generateOrderNumber();

        expect(number, matches(RegExp(r'^ORD-\d{8}-001$')));
      });

      test('increments sequence on subsequent calls', () async {
        // Insert an order for today to simulate an existing order
        await dao.insertOrder(
          TestFixtures.order(id: 'existing-1', createdAt: DateTime.now()),
        );

        final number = await dao.generateOrderNumber();

        expect(number, matches(RegExp(r'^ORD-\d{8}-002$')));
      });
    });

    group('getOrdersByStatus', () {
      test('filters orders by status', () async {
        await dao.insertOrder(TestFixtures.order(id: 'o1', status: 'pending'));
        await dao.insertOrder(
          TestFixtures.order(id: 'o2', status: 'completed'),
        );
        await dao.insertOrder(TestFixtures.order(id: 'o3', status: 'pending'));

        final pending = await dao.getOrdersByStatus('pending');
        final completed = await dao.getOrdersByStatus('completed');

        expect(pending.length, 2);
        expect(completed.length, 1);
        expect(completed.first.id, 'o2');
      });
    });

    group('updateOrderStatus', () {
      test('updates status and updatedAt', () async {
        await dao.insertOrder(TestFixtures.order());

        await dao.updateOrderStatus('order-001', 'completed');

        final order = await dao.getOrderById('order-001');
        expect(order!.status, 'completed');
      });
    });

    group('getOrderWithItems', () {
      test('returns order with items and addons', () async {
        await dao.insertOrder(TestFixtures.order());
        await dao.insertOrderItems([
          TestFixtures.orderItem(id: 'oi-1', orderId: 'order-001'),
          TestFixtures.orderItem(
            id: 'oi-2',
            orderId: 'order-001',
            productName: 'Cappuccino',
          ),
        ]);
        await dao.insertOrderItemAddons([
          TestFixtures.orderItemAddon(id: 'oia-1', orderItemId: 'oi-1'),
        ]);

        final result = await dao.getOrderWithItems('order-001');

        expect(result.order, isNotNull);
        expect(result.order!.id, 'order-001');
        expect(result.itemsWithAddons.length, 2);
        // First item has 1 addon
        expect(result.itemsWithAddons[0].$2.length, 1);
        // Second item has 0 addons
        expect(result.itemsWithAddons[1].$2.length, 0);
      });

      test('returns null order for non-existent ID', () async {
        final result = await dao.getOrderWithItems('non-existent');
        expect(result.order, isNull);
        expect(result.itemsWithAddons, isEmpty);
      });
    });

    group('getTodayOrders', () {
      test('returns only orders created today', () async {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        await dao.insertOrder(
          TestFixtures.order(id: 'today-1', createdAt: now),
        );
        await dao.insertOrder(
          TestFixtures.order(id: 'yesterday-1', createdAt: yesterday),
        );

        final todayOrders = await dao.getTodayOrders();

        expect(todayOrders.length, 1);
        expect(todayOrders.first.id, 'today-1');
      });
    });
  });
}
