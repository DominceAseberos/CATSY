import 'package:catsy_pos/domain/entities/inventory_item.dart';
import 'package:catsy_pos/data/remote/dtos/inventory_dto.dart';

class InventoryMapper {
  static InventoryItem fromDto(InventoryDto dto) => InventoryItem(
    id: dto.id,
    productId: dto.productId,
    productName: dto.productName,
    currentStock: dto.currentStock,
    minStock: dto.minStock,
    unit: dto.unit,
    lastRestocked: DateTime.tryParse(dto.lastRestocked) ?? DateTime.now(),
  );

  static InventoryDto toDto(InventoryItem entity) => InventoryDto(
    id: entity.id,
    productId: entity.productId,
    productName: entity.productName,
    currentStock: entity.currentStock,
    minStock: entity.minStock,
    unit: entity.unit,
    lastRestocked: entity.lastRestocked.toIso8601String(),
  );
}
