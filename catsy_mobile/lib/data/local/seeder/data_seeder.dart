import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../providers.dart';

final dataSeederProvider = Provider((ref) => DataSeeder(ref));

class DataSeeder {
  final Ref _ref;
  final _uuid = const Uuid();

  DataSeeder(this._ref);

  Future<void> seedProductsAndInventory() async {
    final productDao = _ref.read(productDaoProvider);
    final inventoryDao = _ref.read(inventoryDaoProvider);

    // 1. Categories
    final categories = [
      'Coffee',
      'Tea',
      'Pastries',
      'Sandwiches',
      'Merchandise',
    ];

    final categoryIds = <String, String>{}; // Name -> ID

    for (var i = 0; i < categories.length; i++) {
      final id = _uuid.v4();
      categoryIds[categories[i]] = id;
      await productDao.upsertCategory(
        CategoriesTableCompanion(
          id: Value(id),
          name: Value(categories[i]),
          sortOrder: Value(i),
          createdAt: Value(DateTime.now()),
        ),
      );
    }

    // 2. Products & Inventory
    final products = [
      // Coffee
      _ProductSeed('Espresso', 3.50, 'Coffee', 100),
      _ProductSeed('Latte', 4.50, 'Coffee', 50),
      _ProductSeed('Cappuccino', 4.50, 'Coffee', 40),
      _ProductSeed('Americano', 3.75, 'Coffee', 80),
      _ProductSeed('Mocha', 5.00, 'Coffee', 30),
      // Tea
      _ProductSeed('Green Tea', 3.00, 'Tea', 60),
      _ProductSeed('Earl Grey', 3.00, 'Tea', 55),
      _ProductSeed('Matcha Latte', 5.50, 'Tea', 20), // Low stock candidate
      // Pastries
      _ProductSeed('Croissant', 3.00, 'Pastries', 15),
      _ProductSeed('Muffin', 2.50, 'Pastries', 12),
      _ProductSeed('Scone', 2.75, 'Pastries', 8), // Low stock
      // Sandwiches
      _ProductSeed('Club Sandwich', 8.50, 'Sandwiches', 10),
      _ProductSeed('Panini', 7.50, 'Sandwiches', 0), // Out of stock
      // Merch
      _ProductSeed('Cat Mug', 12.00, 'Merchandise', 5),
    ];

    for (var p in products) {
      final pid = _uuid.v4();
      final catId = categoryIds[p.category]!;

      // Upsert Product
      await productDao.upsertProduct(
        ProductsTableCompanion(
          id: Value(pid),
          name: Value(p.name),
          price: Value(p.price),
          categoryId: Value(catId),
          isAvailable: const Value(true),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Upsert Inventory
      await inventoryDao.upsertInventoryItem(
        InventoryTableCompanion(
          id: Value(_uuid.v4()),
          productId: Value(pid),
          productName: Value(p.name),
          currentStock: Value(p.stock),
          minStock: const Value(10),
          unit: const Value('pcs'),
          lastRestocked: Value(DateTime.now()),
        ),
      );
    }
  }
}

class _ProductSeed {
  final String name;
  final double price;
  final String category;
  final int stock;

  _ProductSeed(this.name, this.price, this.category, this.stock);
}
