import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catsy_pos/config/theme/app_colors.dart';
import 'package:catsy_pos/presentation/dashboard/providers/dashboard_provider.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(restaurantOpenProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.dashboardCard,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Logo / Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dashboardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.dashboardPink,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Title (no subtitle per reference screenshot)
            const Text(
              'Cashier POS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const Spacer(),

            // Online Status Badge
            GestureDetector(
              onTap: () {
                ref.read(restaurantOpenProvider.notifier).toggle();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppColors.dashboardGreen.withValues(alpha: 0.1)
                      : AppColors.dashboardRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline
                        ? AppColors.dashboardGreen.withValues(alpha: 0.3)
                        : AppColors.dashboardRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? AppColors.dashboardGreen
                            : AppColors.dashboardRed,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isOnline
                            ? AppColors.dashboardGreen
                            : AppColors.dashboardRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
