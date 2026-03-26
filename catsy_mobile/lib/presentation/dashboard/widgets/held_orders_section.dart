import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catsy_pos/presentation/dashboard/providers/dashboard_data_provider.dart';
import 'package:catsy_pos/config/theme/app_colors.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';

class HeldOrdersSection extends ConsumerWidget {
  const HeldOrdersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heldOrdersAsync = ref.watch(heldOrdersProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.add,
                    color: AppColors.dashboardPink,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Held Orders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // Red circle badge count
              if (heldOrdersAsync.isNotEmpty)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.dashboardRed,
                  ),
                  child: Center(
                    child: Text(
                      '${heldOrdersAsync.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (heldOrdersAsync.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No held orders.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: heldOrdersAsync.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = heldOrdersAsync[index];
                return _HeldOrderCard(order: order, index: index + 1);
              },
            ),
        ],
      ),
    );
  }
}

class _HeldOrderCard extends StatelessWidget {
  final OrdersTableData order;
  final int index;
  const _HeldOrderCard({required this.order, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dashboardCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer #$index',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ₱${order.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              // Proceed payment logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dashboardPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
            child: const Text('Proceed Payment'),
          ),
        ],
      ),
    );
  }
}
