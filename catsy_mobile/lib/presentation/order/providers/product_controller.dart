import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catsy_pos/domain/entities/product.dart';
import 'package:catsy_pos/domain/entities/category.dart';
import 'package:catsy_pos/data/local/providers.dart';

// ── State ────────────────────────────────────────────────────────────────────

class SelectedCategory extends Notifier<Category?> {
  @override
  Category? build() => null;

  void setCategory(Category? category) => state = category;
}

final selectedCategoryProvider = NotifierProvider<SelectedCategory, Category?>(
  SelectedCategory.new,
);

class ProductSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final productSearchQueryProvider = NotifierProvider<ProductSearchQuery, String>(
  ProductSearchQuery.new,
);

// ── Stream Providers ─────────────────────────────────────────────────────────

/// Watches all categories.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchCategories();
});

/// Watches products, filtered by selected category and search query.
/// Done in-memory for simplicity for now, but scalable via repo methods later.
final filteredProductsProvider = StreamProvider<List<Product>>((ref) async* {
  final repository = ref.watch(productRepositoryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(productSearchQueryProvider).toLowerCase();

  // Watch all products from DB
  final allProductsStream = repository.watchProducts();

  await for (final products in allProductsStream) {
    var validProducts = products.where((p) => p.isAvailable).toList();

    // 1. Filter by Category
    if (selectedCategory != null) {
      validProducts = validProducts
          .where((p) => p.categoryId == selectedCategory.id)
          .toList();
    }

    // 2. Filter by Search
    if (searchQuery.isNotEmpty) {
      validProducts = validProducts
          .where(
            (p) =>
                p.name.toLowerCase().contains(searchQuery) ||
                (p.description?.toLowerCase().contains(searchQuery) ?? false),
          )
          .toList();
    }

    yield validProducts;
  }
});
