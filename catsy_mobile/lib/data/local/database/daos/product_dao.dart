import 'package:drift/drift.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/tables/products_table.dart';
import 'package:catsy_pos/data/local/database/tables/categories_table.dart';
import 'package:catsy_pos/data/local/database/tables/addons_table.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [ProductsTable, CategoriesTable, AddonsTable])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  // ── Watch ────────────────────────────────────────────────────────────
  Stream<List<ProductsTableData>> watchAllProducts() =>
      select(productsTable).watch();

  // ── Read ─────────────────────────────────────────────────────────────
  Future<List<ProductsTableData>> getAllProducts() =>
      select(productsTable).get();

  Future<ProductsTableData?> getProductById(String id) =>
      (select(productsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<ProductsTableData>> getProductsByCategory(String categoryId) =>
      (select(
        productsTable,
      )..where((t) => t.categoryId.equals(categoryId))).get();

  Future<List<ProductsTableData>> getAvailableProducts() =>
      (select(productsTable)..where((t) => t.isAvailable.equals(true))).get();

  // ── Categories ──────────────────────────────────────────────────────
  Future<List<CategoriesTableData>> getAllCategories() =>
      select(categoriesTable).get();

  Stream<List<CategoriesTableData>> watchAllCategories() =>
      select(categoriesTable).watch();

  // ── Addons ──────────────────────────────────────────────────────────
  Future<List<AddonsTableData>> getAllAddons() => select(addonsTable).get();

  Future<List<AddonsTableData>> getAddonsForProduct(String productId) =>
      (select(addonsTable)..where((t) => t.productId.equals(productId))).get();

  // ── Write ───────────────────────────────────────────────────────────
  Future<void> upsertProduct(ProductsTableCompanion product) =>
      into(productsTable).insertOnConflictUpdate(product);

  Future<void> upsertAll(List<ProductsTableCompanion> products) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(productsTable, products);
    });
  }

  Future<void> upsertCategory(CategoriesTableCompanion category) =>
      into(categoriesTable).insertOnConflictUpdate(category);

  Future<void> upsertAddon(AddonsTableCompanion addon) =>
      into(addonsTable).insertOnConflictUpdate(addon);
}
