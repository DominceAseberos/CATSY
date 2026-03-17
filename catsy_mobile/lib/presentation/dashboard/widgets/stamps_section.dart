import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_data_provider.dart';
import '../../../config/theme/app_colors.dart';

class StampsSection extends ConsumerWidget {
  const StampsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stampCountsAsync = ref.watch(stampCountsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.loyalty_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Stamps',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          stampCountsAsync.when(
            data: (counts) {
              return Row(
                children: [
                  Expanded(
                    child: _StampCard(
                      title: 'Claimed',
                      count: '${counts.claimed}',
                      color: AppColors.dashboardPink,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StampCard(
                      title: 'Unclaimed',
                      count: '${counts.unclaimed}',
                      color: AppColors.dashboardPurple,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => const Center(child: Text('Error loading stamps')),
          ),
        ],
      ),
    );
  }
}

class _StampCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const _StampCard({
    Key? key,
    required this.title,
    required this.count,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.dashboardCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
