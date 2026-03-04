import '../../../core/network/api_client.dart';
import '../dtos/product_dto.dart';
import '../dtos/category_dto.dart';

class ProductRemoteSource {
  final ApiClient _api;

  ProductRemoteSource(this._api);

  Future<List<ProductDto>> fetchAllProducts() async {
    final data = await _api.get('/products', auth: false) as List<dynamic>;
    return data
        .map((e) => ProductDto.fromJson(_mapProduct(e as Map<String, dynamic>)))
        .toList();
  }

  Future<List<CategoryDto>> fetchCategories() async {
    final data = await _api.get('/categories', auth: false) as List<dynamic>;
    return data
        .map(
          (e) => CategoryDto.fromJson(_mapCategory(e as Map<String, dynamic>)),
        )
        .toList();
  }

  Future<List<ProductDto>> fetchProductsSince(DateTime since) async {
    final data =
        await _api.get(
              '/products',
              queryParams: {'updated_since': since.toIso8601String()},
              auth: false,
            )
            as List<dynamic>;
    return data
        .map((e) => ProductDto.fromJson(_mapProduct(e as Map<String, dynamic>)))
        .toList();
  }

  Future<ProductDto> upsertProduct(Map<String, dynamic> body) async {
    final data =
        await _api.post('/admin/products', body) as Map<String, dynamic>;
    return ProductDto.fromJson(_mapProduct(data));
  }

  Future<void> deleteProduct(String id) => _api.delete('/admin/products/$id');

  Map<String, dynamic> _mapProduct(Map<String, dynamic> api) {
    return {
      'id': (api['product_id'] ?? api['id'] ?? 'unknown').toString(),
      'name': api['product_name'] ?? api['name'] ?? 'Unnamed Product',
      'description': api['product_description'] ?? api['description'],
      'price': (api['product_price'] ?? api['price'] ?? 0.0).toDouble(),
      'category_id': (api['category_id'] ?? '0').toString(),
      'image_url': api['product_image'] ?? api['image_url'],
      'is_available':
          api['product_is_available'] ?? api['is_available'] ?? true,
      'created_at': api['product_created'] ??
          api['created_at'] ??
          DateTime.now().toIso8601String(),
      'updated_at': api['updated_at'] ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _mapCategory(Map<String, dynamic> api) {
    return {
      'id': (api['category_id'] ?? '0').toString(),
      'name': api['name'] ?? 'Unnamed Category',
      'description': api['description'],
      'image_url': api['image_url'],
      'sort_order': api['sort_order'] ?? 0,
      'updated_at': api['updated_at'] ??
          api['created_at'] ??
          DateTime.now().toIso8601String(),
    };
  }
}
