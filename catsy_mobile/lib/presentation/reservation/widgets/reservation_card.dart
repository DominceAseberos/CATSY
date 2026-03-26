import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catsy_pos/config/theme/app_colors.dart';
import 'package:catsy_pos/domain/entities/reservation.dart';
import 'package:catsy_pos/domain/enums/reservation_status.dart';
import 'package:catsy_pos/presentation/reservation/providers/reservation_provider.dart';

class ReservationCard extends ConsumerWidget {
  final Reservation reservation;

  const ReservationCard({super.key, required this.reservation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getStatusColor(reservation.status);
    final isPending = reservation.status == ReservationStatus.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name + Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.customerName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (reservation.customerPhone != null)
                        Text(
                          reservation.customerPhone!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    reservation.status.label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Details Grid
            Row(
              children: [
                _DetailItem(
                  icon: Icons.calendar_today,
                  label: _formatDate(reservation.reservationDate),
                ),
                const SizedBox(width: 24),
                _DetailItem(
                  icon: Icons.access_time,
                  label: _formatTime(reservation.reservationTime),
                ),
                const SizedBox(width: 24),
                _DetailItem(
                  icon: Icons.people,
                  label: '${reservation.partySize} Guests',
                ),
              ],
            ),

            if (reservation.notes != null && reservation.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Note: ${reservation.notes}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],

            // Actions for Pending Reservations
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Use real staff ID from AuthProvider in Phase 3
                        const staffId = 'staff-001';
                        ref
                            .read(reservationControllerProvider.notifier)
                            .approveReservation(reservation.id, staffId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],

            // Handled By Info
            if (!isPending && reservation.handledBy != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Handled by: ${reservation.handledBy}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppColors.warning;
      case ReservationStatus.approved:
        return AppColors.success;
      case ReservationStatus.rejected:
        return AppColors.error;
      case ReservationStatus.cancelled:
        return AppColors.textSecondary;
      case ReservationStatus.completed:
        return AppColors.info;
    }
  }

  String _formatDate(DateTime date) {
    // Simple formatter. Ideally use intl package.
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Reservation'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason (Optional)',
            hintText: 'e.g. Fully booked',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Use real staff ID from AuthProvider
              const staffId = 'staff-001';
              ref
                  .read(reservationControllerProvider.notifier)
                  .rejectReservation(
                    reservation.id,
                    staffId,
                    reasonController.text.trim(),
                  );
              Navigator.pop(context);
            },
            child: const Text(
              'Reject',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
