import 'package:catsy_pos/core/network/api_client.dart';
import 'package:catsy_pos/data/remote/dtos/inventory_dto.dart';

class InventoryRemoteSource {
  final ApiClient _api;

  InventoryRemoteSource(this._api);

  Future<List<InventoryDto>> fetchAllInventory() async {
    final data = await _api.get('/admin/materials') as List<dynamic>;
    return data
        .map((e) => InventoryDto.fromJson(_mapInventory(e as Map<String, dynamic>)))
        .toList();
  }

  Future<List<InventoryDto>> fetchInventorySince(DateTime since) async {
    final data =
        await _api.get(
              '/admin/materials',
              queryParams: {'updated_since': since.toIso8601String()},
            )
            as List<dynamic>;
    return data
        .map((e) => InventoryDto.fromJson(_mapInventory(e as Map<String, dynamic>)))
        .toList();
  }

  Future<InventoryDto> adjustStock(String id, Map<String, dynamic> body) async {
    final data =
        await _api.put('/admin/materials/$id', body) as Map<String, dynamic>;
    return InventoryDto.fromJson(_mapInventory(data));
  }

  Map<String, dynamic> _mapInventory(Map<String, dynamic> api) {
    // FALLBACK: If product_id is missing, use material_id/id
    // This allows syncing raw materials that aren't directly linked to a single product.
    final id = (api['material_id'] ?? api['id'])?.toString() ?? 'unknown_id';
    final productId = api['product_id']?.toString() ?? id;

    return {
      'id': id,
      'product_id': productId,
      'product_name': api['material_name'] ?? api['product_name'] ?? 'Unknown Item',
      'current_stock': (api['material_stock'] ?? api['current_stock'] ?? 0).toInt(),
      'min_stock':
          (api['material_reorder_level'] ?? api['min_stock'] ?? 0).toInt(),
      'unit': api['material_unit'] ?? api['unit'] ?? 'pcs',
      'last_restocked':
          api['last_restocked'] ??
          api['material_updated'] ??
          api['updated_at'] ??
          DateTime.now().toIso8601String(),
    };
  }
}
