import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../domain/entities/cafe_table.dart';
import '../../../../domain/enums/table_status.dart';
import '../providers/table_provider.dart';

class TableTile extends ConsumerWidget {
  final CafeTable table;
  final VoidCallback? onTap;

  const TableTile({
    super.key,
    required this.table,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getStatusColor(table.status);
    final icon = _getStatusIcon(table.status);

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          _showQuickAction(context, ref);
        }
      },
      onLongPress: () => _showFullMenu(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 4),
            Text(
              table.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              '${table.capacity}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                table.status.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return AppColors.success;
      case TableStatus.reserved:
        return AppColors.info;
      case TableStatus.occupied:
        return AppColors.error;
      case TableStatus.billReady:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return Icons.check_circle_outline;
      case TableStatus.reserved:
        return Icons.bookmark_outline;
      case TableStatus.occupied:
        return Icons.person_outline;
      case TableStatus.billReady:
        return Icons.receipt_long_outlined;
    }
  }

  void _showQuickAction(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIcon(table.status),
                    color: _getStatusColor(table.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Table ${table.label}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            if (table.status == TableStatus.available) ...[
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                title: const Text('New Order'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_outlined, color: AppColors.info),
                title: const Text('Mark Occupied'),
                onTap: () {
                  ref.read(tableControllerProvider.notifier).updateStatus(
                        table.id,
                        TableStatus.occupied,
                      );
                  Navigator.pop(context);
                },
              ),
            ],
            if (table.status == TableStatus.occupied) ...[
              ListTile(
                leading: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                title: const Text('Add Items'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: AppColors.warning),
                title: const Text('Request Bill'),
                onTap: () {
                  ref.read(tableControllerProvider.notifier).updateStatus(
                        table.id,
                        TableStatus.billReady,
                      );
                  Navigator.pop(context);
                },
              ),
            ],
            if (table.status == TableStatus.billReady) ...[
              ListTile(
                leading: const Icon(Icons.payment, color: AppColors.success),
                title: const Text('Process Payment'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
            if (table.status == TableStatus.reserved) ...[
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.error),
                title: const Text('Customer Arrived'),
                onTap: () {
                  ref.read(tableControllerProvider.notifier).updateStatus(
                        table.id,
                        TableStatus.occupied,
                      );
                  Navigator.pop(context);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.clear, color: AppColors.textSecondary),
              title: const Text('Clear Table'),
              onTap: () {
                ref.read(tableControllerProvider.notifier).updateStatus(
                      table.id,
                      TableStatus.available,
                    );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFullMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Edit Table'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Table'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
