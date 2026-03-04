import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/reservations_table.dart';

part 'reservation_dao.g.dart';

@DriftAccessor(tables: [ReservationsTable])
class ReservationDao extends DatabaseAccessor<AppDatabase>
    with _$ReservationDaoMixin {
  ReservationDao(super.db);

  // ── Watch ────────────────────────────────────────────────────────────
  Stream<List<ReservationsTableData>> watchReservations({String? status}) {
    final query = select(reservationsTable)
      ..orderBy([(t) => OrderingTerm.asc(t.reservationDate)]);
    if (status != null) {
      query.where((t) => t.status.equals(status));
    }
    return query.watch();
  }

  Stream<int> watchPendingCount() {
    final query = selectOnly(reservationsTable)
      ..addColumns([reservationsTable.id.count()])
      ..where(reservationsTable.status.equals('pending'));
    return query
        .map((row) => row.read(reservationsTable.id.count()) ?? 0)
        .watchSingle();
  }

  // ── Read ─────────────────────────────────────────────────────────────
  Future<ReservationsTableData?> getReservationById(String id) => (select(
    reservationsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<ReservationsTableData>> getReservationsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(reservationsTable)
          ..where((t) => t.reservationDate.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.asc(t.reservationTime)]))
        .get();
  }

  // ── Write ───────────────────────────────────────────────────────────
  Future<void> insertReservation(ReservationsTableCompanion reservation) =>
      into(reservationsTable).insert(reservation);

  Future<void> updateReservationStatus(
    String id,
    String status, {
    String? handledBy,
    String? rejectionReason,
  }) => (update(reservationsTable)..where((t) => t.id.equals(id))).write(
    ReservationsTableCompanion(
      status: Value(status),
      updatedAt: Value(DateTime.now()),
      handledBy: handledBy != null ? Value(handledBy) : const Value.absent(),
      rejectionReason: rejectionReason != null
          ? Value(rejectionReason)
          : const Value.absent(),
    ),
  );
}
