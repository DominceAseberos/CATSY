import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/product.dart';
import '../entities/category.dart';

abstract class ProductRepository {
  /// Watch all products (stream).
  Stream<List<Product>> watchProducts();

  /// Watch all categories (stream).
  Stream<List<Category>> watchCategories();

  /// Get all categories (future).
  Future<Either<Failure, List<Category>>> getAllCategories();

  /// Get products by category ID.
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categoryId,
  );

  /// Search products by name (local data).
  Future<Either<Failure, List<Product>>> searchProducts(String query);

  // Future<Either<Failure, void>> syncProducts(); // Phase 7
}
