import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../domain/entities/cafe_table.dart';
import '../../../../domain/enums/table_status.dart';
import '../providers/table_provider.dart';

class TableManagementScreen extends ConsumerWidget {
  const TableManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Management'),
        actions: [
          // Filter or other actions can go here
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTableDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: tablesAsync.when(
        data: (tables) {
          if (tables.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_restaurant,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('No tables found'),
                  TextButton(
                    onPressed: () => _seedTestData(ref),
                    child: const Text('Seed Test Data'),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Responsive? Maybe 2 on phone, 4 on tablet
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              return _TableCard(table: table);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAddTableDialog(BuildContext context, WidgetRef ref) {
    final labelController = TextEditingController();
    final capacityController = TextEditingController(text: '4');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Table'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Table Label (e.g. T1)',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final label = labelController.text.trim();
              final capacity =
                  int.tryParse(capacityController.text.trim()) ?? 4;
              if (label.isNotEmpty) {
                ref
                    .read(tableControllerProvider.notifier)
                    .addTable(label, capacity);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _seedTestData(WidgetRef ref) {
    final notifier = ref.read(tableControllerProvider.notifier);
    notifier.addTable('T1', 2);
    notifier.addTable('T2', 4);
    notifier.addTable('T3', 4);
    notifier.addTable('T4', 6);
    notifier.addTable('T5', 8);
  }
}

class _TableCard extends ConsumerWidget {
  final CafeTable table;

  const _TableCard({required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getStatusColor(table.status);

    return GestureDetector(
      onTap: () => _showStatusDialog(context, ref, table),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_bar, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              table.label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '${table.capacity} Seats',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              table.status.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
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
        return AppColors.success; // Green
      case TableStatus.reserved:
        return AppColors.warning; // Yellow/Orange
      case TableStatus.occupied:
        return AppColors.error; // Red
      case TableStatus.billReady:
        return AppColors.info; // Blue
    }
  }

  void _showStatusDialog(BuildContext context, WidgetRef ref, CafeTable table) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Table ${table.label}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Current Status: ${table.status.label}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditTableDialog(context, ref, table);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(context, ref, table.id);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            _StatusOption(
              label: 'Available',
              color: AppColors.success,
              isSelected: table.status == TableStatus.available,
              onTap: () {
                ref
                    .read(tableControllerProvider.notifier)
                    .updateStatus(table.id, TableStatus.available);
                Navigator.pop(context);
              },
            ),
            _StatusOption(
              label: 'Reserved',
              color: AppColors.warning,
              isSelected: table.status == TableStatus.reserved,
              onTap: () {
                ref
                    .read(tableControllerProvider.notifier)
                    .updateStatus(table.id, TableStatus.reserved);
                Navigator.pop(context);
              },
            ),
            _StatusOption(
              label: 'Occupied',
              color: AppColors.error,
              isSelected: table.status == TableStatus.occupied,
              onTap: () {
                ref
                    .read(tableControllerProvider.notifier)
                    .updateStatus(table.id, TableStatus.occupied);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTableDialog(
    BuildContext context,
    WidgetRef ref,
    CafeTable table,
  ) {
    final labelController = TextEditingController(text: table.label);
    final capacityController = TextEditingController(
      text: table.capacity.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Table'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Table Label'),
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final label = labelController.text.trim();
              final capacity =
                  int.tryParse(capacityController.text.trim()) ?? 4;
              if (label.isNotEmpty) {
                final updatedTable = CafeTable(
                  id: table.id,
                  label: label,
                  capacity: capacity,
                  status: table.status,
                  currentOrderId: table.currentOrderId,
                );
                ref
                    .read(tableControllerProvider.notifier)
                    .updateTable(updatedTable);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String tableId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(tableControllerProvider.notifier).deleteTable(tableId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.circle, color: color),
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: color) : null,
      onTap: onTap,
    );
  }
}
