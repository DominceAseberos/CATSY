import 'package:flutter_test/flutter_test.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/daos/inventory_dao.dart';

import '../../../helpers/test_database.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  late AppDatabase db;
  late InventoryDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = db.inventoryDao;
  });

  tearDown(() => db.close());

  group('InventoryDao', () {
    group('upsertInventoryItem & getInventoryForProduct', () {
      test('inserts and retrieves inventory item', () async {
        await dao.upsertInventoryItem(TestFixtures.inventoryItem());

        final item = await dao.getInventoryForProduct('prod-001');

        expect(item, isNotNull);
        expect(item!.currentStock, 50);
        expect(item.minStock, 10);
      });

      test('upserts existing item', () async {
        await dao.upsertInventoryItem(TestFixtures.inventoryItem());
        await dao.upsertInventoryItem(
          TestFixtures.inventoryItem(currentStock: 99),
        );

        final item = await dao.getInventoryForProduct('prod-001');
        expect(item!.currentStock, 99);
      });
    });

    group('deductStock', () {
      test('reduces currentStock by given quantity', () async {
        await dao.upsertInventoryItem(
          TestFixtures.inventoryItem(currentStock: 50),
        );

        await dao.deductStock('prod-001', 5);

        final item = await dao.getInventoryForProduct('prod-001');
        expect(item!.currentStock, 45);
      });

      test('clamps stock to 0 when deducting more than available', () async {
        await dao.upsertInventoryItem(
          TestFixtures.inventoryItem(currentStock: 3),
        );

        await dao.deductStock('prod-001', 10);

        final item = await dao.getInventoryForProduct('prod-001');
        expect(item!.currentStock, 0);
      });

      test('does nothing for non-existent product', () async {
        // Should not throw
        await dao.deductStock('non-existent', 5);
      });
    });

    group('getLowStockItems', () {
      test('returns items where currentStock <= minStock', () async {
        await dao.upsertInventoryItem(
          TestFixtures.inventoryItem(
            id: 'inv-1',
            productId: 'p1',
            currentStock: 5,
            minStock: 10,
          ),
        );
        await dao.upsertInventoryItem(
          TestFixtures.inventoryItem(
            id: 'inv-2',
            productId: 'p2',
            currentStock: 20,
            minStock: 10,
          ),
        );
        await dao.upsertInventoryItem(
          TestFixtures.inventoryItem(
            id: 'inv-3',
            productId: 'p3',
            currentStock: 10,
            minStock: 10,
          ),
        );

        final lowStock = await dao.getLowStockItems();

        expect(lowStock.length, 2); // inv-1 (5<=10) and inv-3 (10<=10)
        expect(lowStock.map((e) => e.id).toSet(), {'inv-1', 'inv-3'});
      });
    });

    group('getStockForProduct', () {
      test('returns current stock count', () async {
        await dao.upsertInventoryItem(
          TestFixtures.inventoryItem(currentStock: 42),
        );

        final stock = await dao.getStockForProduct('prod-001');
        expect(stock, 42);
      });

      test('returns 0 for non-existent product', () async {
        final stock = await dao.getStockForProduct('non-existent');
        expect(stock, 0);
      });
    });
  });
}
