import 'package:flutter/material.dart';
import '../../../../domain/entities/product.dart';
import '../../../../config/theme/app_colors.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int currentStock;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.currentStock,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = currentStock <= 0;
    final isLowStock =
        currentStock <= 5 &&
        !isOutOfStock; // Threshold could be from item.minStock

    return GestureDetector(
      onTap: isOutOfStock ? null : onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isOutOfStock ? Colors.grey.shade200 : Colors.white,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Placeholder
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.fastfood,
                        size: 48,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                // Details
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Stock Indicator
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOutOfStock
                                  ? Colors.red
                                  : isLowStock
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOutOfStock
                                ? 'Out of Stock'
                                : '$currentStock in stock',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOutOfStock
                                  ? Colors.red
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Out of Stock Overlay
            if (isOutOfStock)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Chip(
                      label: Text('SOLD OUT'),
                      backgroundColor: Colors.red,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
