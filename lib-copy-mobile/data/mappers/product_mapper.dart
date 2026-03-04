import '../../domain/entities/product.dart';
import '../remote/dtos/product_dto.dart';

class ProductMapper {
  static Product fromDto(ProductDto dto) => Product(
    id: dto.id,
    name: dto.name,
    description: dto.description,
    price: dto.price,
    categoryId: dto.categoryId,
    imageUrl: dto.imageUrl,
    isAvailable: dto.isAvailable,
    createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
    updatedAt: DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
  );

  static ProductDto toDto(Product entity) => ProductDto(
    id: entity.id,
    name: entity.name,
    description: entity.description,
    price: entity.price,
    categoryId: entity.categoryId,
    imageUrl: entity.imageUrl,
    isAvailable: entity.isAvailable,
    createdAt: entity.createdAt.toIso8601String(),
    updatedAt: entity.updatedAt.toIso8601String(),
  );
}
