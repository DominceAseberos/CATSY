import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../domain/entities/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../../common_widgets/empty_state_widget.dart';
import '../../common_widgets/shimmer_loading.dart';
import '../../common_widgets/animated_list_item.dart';

class StockOverviewScreen extends ConsumerWidget {
  const StockOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryListProvider);
    final lowStockOnly = ref.watch(lowStockOnlyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Overview'),
        actions: [
          FilterChip(
            label: const Text('Low Stock Only'),
            selected: lowStockOnly,
            onSelected: (val) {
              ref.read(lowStockOnlyProvider.notifier).toggle();
            },
            backgroundColor: Colors.transparent,
            selectedColor: Colors.orange.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: lowStockOnly ? Colors.orange : Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: inventoryAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyStateWidget(
              icon: lowStockOnly
                  ? Icons.check_circle_outline
                  : Icons.inventory_2_outlined,
              title: lowStockOnly
                  ? 'No low stock items!'
                  : 'No inventory items found.',
              subtitle: lowStockOnly
                  ? 'All items are sufficiently stocked.'
                  : 'Add items to see them here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              return Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return AnimatedListItem(
                  index: index,
                  child: _InventoryItemTile(item: item),
                );
              },
            ),
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 8,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) => const ShimmerListTile(),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _InventoryItemTile extends ConsumerWidget {
  final InventoryItem item;

  const _InventoryItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLow = item.isLowStock;
    final isOut = item.currentStock <= 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isOut
            ? Colors.red.withValues(alpha: 0.1)
            : isLow
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        child: Icon(
          isOut
              ? Icons.error_outline
              : isLow
              ? Icons.warning_amber
              : Icons.check_circle_outline,
          color: isOut
              ? Colors.red
              : isLow
              ? Colors.orange
              : Colors.green,
        ),
      ),
      title: Text(
        item.productName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Min Stock: ${item.minStock} ${item.unit} | Last Restocked: ${_formatDate(item.lastRestocked)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${item.currentStock} ${item.unit}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isOut
                  ? Colors.red
                  : isLow
                  ? Colors.orange
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showUpdateDialog(context, ref, item),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  void _showUpdateDialog(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) {
    final controller = TextEditingController(
      text: item.currentStock.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock: ${item.productName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New Quantity'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) {
                ref
                    .read(inventoryControllerProvider.notifier)
                    .updateStock(item.productId, val);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
