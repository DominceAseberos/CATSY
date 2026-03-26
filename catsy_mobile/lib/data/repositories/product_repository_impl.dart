import 'package:dartz/dartz.dart';
import 'package:catsy_pos/core/error/failures.dart';
import 'package:catsy_pos/domain/entities/product.dart';
import 'package:catsy_pos/domain/entities/category.dart';
import 'package:catsy_pos/domain/repositories/product_repository.dart';
import 'package:catsy_pos/data/local/database/daos/product_dao.dart';
import 'package:catsy_pos/data/local/database/app_database.dart'; // For generated data classes

class ProductRepositoryImpl implements ProductRepository {
  final ProductDao _productDao;

  ProductRepositoryImpl({required ProductDao productDao})
    : _productDao = productDao;

  @override
  Stream<List<Product>> watchProducts() {
    return _productDao.watchAllProducts().map(
      (rows) => rows.map(_mapProduct).toList(),
    );
  }

  @override
  Stream<List<Category>> watchCategories() {
    return _productDao.watchAllCategories().map(
      (rows) => rows.map(_mapCategory).toList(),
    );
  }

  @override
  Future<Either<Failure, List<Category>>> getAllCategories() async {
    try {
      final rows = await _productDao.getAllCategories();
      return Right(rows.map(_mapCategory).toList());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get categories: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categoryId,
  ) async {
    try {
      final rows = await _productDao.getProductsByCategory(categoryId);
      return Right(rows.map(_mapProduct).toList());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get products: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> searchProducts(String query) async {
    try {
      // Basic local search: fetch all and filter.
      // Optimized approach would use LIKE query in DAO.
      final allRows = await _productDao.getAllProducts();
      final filtered = allRows.where(
        (p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            (p.description?.toLowerCase().contains(query.toLowerCase()) ??
                false),
      );
      return Right(filtered.map(_mapProduct).toList());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to search products: $e'));
    }
  }

  Product _mapProduct(ProductsTableData p) {
    return Product(
      id: p.id,
      name: p.name,
      description: p.description,
      price: p.price,
      categoryId: p.categoryId,
      imageUrl: p.imageUrl,
      isAvailable: p.isAvailable,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    );
  }

  Category _mapCategory(CategoriesTableData c) {
    return Category(
      id: c.id,
      name: c.name,
      description: c.description,
      sortOrder: c.sortOrder,
      createdAt: c.createdAt,
    );
  }
}
