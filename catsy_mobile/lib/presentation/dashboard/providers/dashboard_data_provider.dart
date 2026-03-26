import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catsy_pos/domain/entities/reservation.dart';
import 'package:catsy_pos/domain/entities/reward.dart';
import 'package:catsy_pos/domain/entities/customer.dart';
import 'package:catsy_pos/data/local/providers.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/presentation/reservation/providers/reservation_provider.dart';
import 'package:catsy_pos/domain/enums/order_status.dart';
import 'package:catsy_pos/domain/enums/payment_status.dart';
import 'package:catsy_pos/domain/enums/reservation_status.dart';

// ── Held Orders ────────────────────────────────────────────────────────
final heldOrdersProvider = Provider<List<OrdersTableData>>((ref) {
  final activeOrdersAsync = ref.watch(activeOrdersProvider);

  return activeOrdersAsync.maybeWhen(
    data: (orders) => orders.where((order) {
      // Assuming 'held' logic means not paid and not completed/cancelled
      return order.paymentStatus == PaymentStatus.pending.name ||
          order.status ==
              OrderStatus.preparing.name; // Tweak logic if necessary
    }).toList(),
    orElse: () => [],
  );
});

// ── Pending Reservation Requests ──────────────────────────────────────────
final pendingReservationRequestsProvider = Provider<List<Reservation>>((ref) {
  // Use the existing provider, assuming filter is "All" or includes pending.
  // Actually, wait, filteredReservationsProvider depends on UI filter state.
  // It's safer to watch the DAO directly if we need all pending independently.
  // But wait, I'll watch the reservations provider, assuming it serves general list.
  final reservationsAsync = ref.watch(filteredReservationsProvider);
  return reservationsAsync.maybeWhen(
    data: (reservations) => reservations
        .where((r) => r.status == ReservationStatus.pending)
        .toList(),
    orElse: () => [],
  );
});

// ── Stamp Counts ───────────────────────────────────────────────────────
/// Using StreamProvider for reactive updates from RewardDao.
final stampCountsProvider = StreamProvider<({int claimed, int unclaimed})>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.rewardDao.watchUnclaimedRewards().map((unclaimedRewards) {
    return (
      claimed: 0,
      unclaimed: unclaimedRewards.length,
    ); // Placeholder logic
  });
});

// ── Pending Reward Requests ─────────────────────────────────────────────
class RewardWithCustomer {
  final Reward reward;
  final Customer? customer;
  RewardWithCustomer({required this.reward, this.customer});
}

final pendingRewardRequestsProvider = StreamProvider<List<RewardWithCustomer>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);

  return db.rewardDao.watchActiveRewards().map((activeRewards) {
    final pending = activeRewards
        .where((r) => r.isClaimed == false && r.customerId != null)
        .toList();

    List<RewardWithCustomer> requests = [];
    for (var r in pending) {
      // We would need CustomerDao here.
      // For now, returning without customer details until CustomerDao is brought in.
      requests.add(
        RewardWithCustomer(
          reward: Reward(
            id: r.id,
            name: r.name,
            stampsRequired: r.stampsRequired,
            createdAt: r.createdAt,
            code: r.code,
            customerId: r.customerId,
            isClaimed: r.isClaimed,
          ),
          customer: null,
        ),
      );
    }
    return requests;
  });
});
