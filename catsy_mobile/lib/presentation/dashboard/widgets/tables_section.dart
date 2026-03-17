import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../table_management/providers/table_provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/routes/route_names.dart';
import '../../../domain/enums/table_status.dart';

class TablesSection extends ConsumerWidget {
  const TablesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.table_restaurant_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tables',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Count indicator (occupied/total)
                  tablesAsync.maybeWhen(
                    data: (tables) {
                      final occupied = tables
                          .where((t) => t.status == TableStatus.occupied)
                          .length;
                      return Text(
                        '$occupied/${tables.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed(RouteNames.tableManagement);
                },
                child: const Text(
                  'Edit',
                  style: TextStyle(color: AppColors.dashboardPink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          tablesAsync.when(
            data: (tables) {
              if (tables.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No tables configured.'),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemCount: tables.length,
                itemBuilder: (context, index) {
                  final table = tables[index];

                  Color borderColor;
                  Color bgColor;
                  String statusLabel;

                  switch (table.status) {
                    case TableStatus.available:
                      borderColor = AppColors.border;
                      bgColor = AppColors.dashboardGrey;
                      statusLabel = 'Available';
                      break;
                    case TableStatus.occupied:
                      borderColor = AppColors.dashboardRed;
                      bgColor = AppColors.dashboardCard;
                      statusLabel = 'Occupied';
                      break;
                    case TableStatus.reserved:
                      borderColor = AppColors.dashboardReserved;
                      bgColor = AppColors.dashboardCard;
                      statusLabel = 'Reserved';
                      break;
                    case TableStatus.billReady:
                      borderColor = AppColors.orderPending;
                      bgColor = AppColors.dashboardCard;
                      statusLabel = 'Bill Ready';
                      break;
                  }

                  return InkWell(
                    onTap: () {
                      // Table actions dialog or navigate
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor,
                          width: table.status != TableStatus.available ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            table.label,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: table.status != TableStatus.available
                                  ? borderColor
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: table.status != TableStatus.available
                                  ? borderColor
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}
