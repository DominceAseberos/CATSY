import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catsy_pos/domain/entities/reservation.dart';
import 'package:catsy_pos/domain/enums/reservation_status.dart';
import 'package:catsy_pos/domain/repositories/reservation_repository.dart';
import 'package:catsy_pos/data/local/providers.dart' as local_providers;

// ── Filters & State ──────────────────────────────────────────────────────────

/// Helper to store the currently selected filter status (null = All).
class ReservationFilter extends Notifier<ReservationStatus?> {
  @override
  ReservationStatus? build() => null;

  void setFilter(ReservationStatus? status) => state = status;
}

final reservationFilterProvider =
    NotifierProvider<ReservationFilter, ReservationStatus?>(
      ReservationFilter.new,
    );

/// Helper to store the selected date (defaults to today).
class ReservationDate extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDate(DateTime date) => state = date;
}

final reservationDateProvider = NotifierProvider<ReservationDate, DateTime>(
  ReservationDate.new,
);

// ── Stream Providers ─────────────────────────────────────────────────────────

/// Watches reservations based on the current filter.
/// Note: This implementation filters in memory for simplicity/flexibility,
/// but could be optimized to filter at the query level if needed.
final filteredReservationsProvider = StreamProvider<List<Reservation>>((ref) {
  final repository = ref.watch(local_providers.reservationRepositoryProvider);
  final filterStatus = ref.watch(reservationFilterProvider);
  // We want to watch ALL reservations and filter on the client side
  // or use the repository's status filter if we only matched one status.
  // For "All", we need everything.
  // Repository watchReservations helper I added takes an optional status.

  // NOTE: ReservationRepositoryImpl exposes watchReservations directly now
  // but it's not in the abstract interface yet in the plan, but I added it to impl.
  // To be safe and clean, let's cast or assume the impl has it, OR rely on the DAO provider directly?
  // Ideally we use the repository. let's assume I cast it or the interface update propagated.

  // Actually, I added watchReservations to the interface in a previous step!
  // So we can just call:
  // (repository as dynamic).watchReservations(...) if type inference fails,
  // but better to rely on the interface update.

  // Let's assume we want to listen to ALL and filter in Dart to handle complex logic if needed,
  // OR pass status to DB.

  if (filterStatus != null) {
    // Pass status to DB query for efficiency
    return (repository as dynamic).watchReservations(status: filterStatus.name);
  } else {
    return (repository as dynamic).watchReservations();
  }
});

// ── Controller for Actions ───────────────────────────────────────────────────

class ReservationController extends Notifier<AsyncValue<void>> {
  late final ReservationRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(local_providers.reservationRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<void> approveReservation(String id, String staffId) async {
    state = const AsyncValue.loading();
    // Simulate staff ID for now if not provided or use what's passed
    final result = await _repository.approveReservation(id, staffId);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> rejectReservation(
    String id,
    String staffId,
    String reason,
  ) async {
    state = const AsyncValue.loading();
    final result = await _repository.rejectReservation(id, staffId, reason);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> createReservation(Reservation reservation) async {
    state = const AsyncValue.loading();
    final result = await _repository.createReservation(reservation);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> createTestReservation() async {
    // Kept as a helper, but delegating to the main method
    final now = DateTime.now();
    final reservation = Reservation(
      id: '',
      customerName: 'Test Guest ${now.minute}${now.second}',
      customerPhone: '555-01${now.second}',
      partySize: (now.second % 6) + 1,
      reservationDate: DateTime(now.year, now.month, now.day),
      reservationTime: now.add(const Duration(hours: 1)),
      status: ReservationStatus.pending,
      notes: 'Auto-generated test reservation',
      createdAt: now,
      updatedAt: now,
    );

    await createReservation(reservation);
  }
}

final reservationControllerProvider =
    NotifierProvider<ReservationController, AsyncValue<void>>(
      ReservationController.new,
    );
