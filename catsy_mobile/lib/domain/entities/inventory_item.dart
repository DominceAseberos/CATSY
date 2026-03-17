import 'package:equatable/equatable.dart';

/// Inventory / stock entity.
class InventoryItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final int currentStock;
  final int minStock;
  final String unit; // "pcs", "kg", "ml"
  final DateTime lastRestocked;

  const InventoryItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.currentStock,
    this.minStock = 10,
    this.unit = 'pcs',
    required this.lastRestocked,
  });

  bool get isLowStock => currentStock <= minStock;

  @override
  List<Object?> get props => [id, productId, currentStock];
}
