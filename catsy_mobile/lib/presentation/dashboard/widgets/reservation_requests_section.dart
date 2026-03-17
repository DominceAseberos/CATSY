import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_data_provider.dart';
import '../../reservation/providers/reservation_provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../domain/entities/reservation.dart';

class ReservationRequestsSection extends ConsumerWidget {
  const ReservationRequestsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(pendingReservationRequestsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Reservation Requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Badge count
              if (reservations.isNotEmpty)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.dashboardPurple.withOpacity(0.8),
                  ),
                  child: Center(
                    child: Text(
                      '${reservations.length}',
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
          if (reservations.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No pending reservations.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reservations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = reservations[index];
                return _ReservationCard(reservation: req, index: index + 1);
              },
            ),
        ],
      ),
    );
  }
}

class _ReservationCard extends ConsumerWidget {
  final Reservation reservation;
  final int index;
  const _ReservationCard({
    Key? key,
    required this.reservation,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Verified logic as per user decision (fallback): customerPhone != null && not empty
    final isVerified =
        reservation.customerPhone != null &&
        reservation.customerPhone!.isNotEmpty;
    final timeFormat = DateFormat('ha');

    // Build time range string
    final startTime = timeFormat
        .format(reservation.reservationTime)
        .toLowerCase();
    final endTime = timeFormat
        .format(reservation.reservationTime.add(const Duration(hours: 1)))
        .toLowerCase();

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Reservation #$index',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Verified Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? AppColors.dashboardGreen.withOpacity(0.1)
                            : AppColors.dashboardRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isVerified ? 'Verified' : 'Unverified',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isVerified
                              ? AppColors.dashboardGreen
                              : AppColors.dashboardRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$startTime-$endTime  •  ${reservation.partySize} persons',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reject (X)
              GestureDetector(
                onTap: () {
                  ref
                      .read(reservationControllerProvider.notifier)
                      .rejectReservation(
                        reservation.id,
                        "staff_123",
                        "User rejected",
                      );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.dashboardRed.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.dashboardRed,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Approve (✓)
              GestureDetector(
                onTap: () {
                  ref
                      .read(reservationControllerProvider.notifier)
                      .approveReservation(reservation.id, "staff_123");
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.dashboardGreen.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.dashboardGreen,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
