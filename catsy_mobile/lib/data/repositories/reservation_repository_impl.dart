import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:catsy_pos/core/error/failures.dart';
import 'package:catsy_pos/domain/entities/reservation.dart';
import 'package:catsy_pos/domain/enums/reservation_status.dart';
import 'package:catsy_pos/domain/repositories/reservation_repository.dart';
import 'package:catsy_pos/data/local/database/daos/reservation_dao.dart';
import 'package:catsy_pos/data/local/database/daos/table_dao.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';

/// Phase 1 — LOCAL ONLY. Uses ReservationDao.
class ReservationRepositoryImpl implements ReservationRepository {
  final ReservationDao _reservationDao;
  final TableDao _tableDao;

  ReservationRepositoryImpl({
    required ReservationDao reservationDao,
    required TableDao tableDao,
  }) : _reservationDao = reservationDao,
       _tableDao = tableDao;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, List<Reservation>>> getReservations() async {
    try {
      final rows = await _reservationDao.watchReservations().first;
      return Right(rows.map(_mapToReservation).toList());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get reservations: $e'));
    }
  }

  // NOTE: Added watchReservations to repository interface wasn't explicitly in plan but is needed for stream provider
  Stream<List<Reservation>> watchReservations({String? status}) {
    return _reservationDao
        .watchReservations(status: status)
        .map((rows) => rows.map(_mapToReservation).toList());
  }

  @override
  Future<Either<Failure, List<Reservation>>> getReservationsByDate(
    DateTime date,
  ) async {
    try {
      final rows = await _reservationDao.getReservationsByDate(date);
      return Right(rows.map(_mapToReservation).toList());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get reservations: $e'));
    }
  }

  @override
  Future<Either<Failure, Reservation>> getReservationById(String id) async {
    try {
      final row = await _reservationDao.getReservationById(id);
      if (row == null) {
        return const Left(CacheFailure(message: 'Reservation not found'));
      }
      return Right(_mapToReservation(row));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get reservation: $e'));
    }
  }

  @override
  Future<Either<Failure, Reservation>> createReservation(
    Reservation reservation,
  ) async {
    try {
      final id = reservation.id.isEmpty ? _uuid.v4() : reservation.id;
      final now = DateTime.now();
      await _reservationDao.insertReservation(
        ReservationsTableCompanion(
          id: Value(id),
          customerName: Value(reservation.customerName),
          customerPhone: Value(reservation.customerPhone),
          tableId: Value(reservation.tableId),
          partySize: Value(reservation.partySize),
          reservationDate: Value(reservation.reservationDate),
          reservationTime: Value(reservation.reservationTime),
          status: Value(reservation.status.name),
          notes: Value(reservation.notes),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return Right(
        Reservation(
          id: id,
          customerName: reservation.customerName,
          customerPhone: reservation.customerPhone,
          tableId: reservation.tableId,
          partySize: reservation.partySize,
          reservationDate: reservation.reservationDate,
          reservationTime: reservation.reservationTime,
          status: reservation.status,
          notes: reservation.notes,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to create reservation: $e'));
    }
  }

  @override
  Future<Either<Failure, Reservation>> updateReservationStatus(
    String id,
    String status,
  ) async {
    try {
      await _reservationDao.updateReservationStatus(id, status);
      final row = await _reservationDao.getReservationById(id);
      if (row == null) {
        return const Left(
          CacheFailure(message: 'Reservation not found after update'),
        );
      }
      return Right(_mapToReservation(row));
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to update reservation status: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, Reservation>> approveReservation(
    String id,
    String staffId,
  ) async {
    try {
      // 1. Update reservation status
      await _reservationDao.updateReservationStatus(
        id,
        ReservationStatus.approved.name,
        handledBy: staffId,
      );

      // 2. Fetch reservation to get table ID
      final reservationRow = await _reservationDao.getReservationById(id);
      if (reservationRow == null) {
        return const Left(CacheFailure(message: 'Reservation not found'));
      }

      // 3. Update table status if tableId is present
      if (reservationRow.tableId != null) {
        await _tableDao.updateTableStatus(
          reservationRow.tableId!,
          'reserved', // Using string for now to match TableDao, ideally use Enum
        );
      }

      return Right(_mapToReservation(reservationRow));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to approve reservation: $e'));
    }
  }

  @override
  Future<Either<Failure, Reservation>> rejectReservation(
    String id,
    String staffId,
    String reason,
  ) async {
    try {
      await _reservationDao.updateReservationStatus(
        id,
        ReservationStatus.rejected.name,
        handledBy: staffId,
        rejectionReason: reason,
      );
      final row = await _reservationDao.getReservationById(id);
      if (row == null) {
        return const Left(CacheFailure(message: 'Reservation not found'));
      }
      return Right(_mapToReservation(row));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to reject reservation: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncReservations() async {
    // Phase 1: No-op
    return const Right(null);
  }

  Reservation _mapToReservation(ReservationsTableData r) => Reservation(
    id: r.id,
    customerName: r.customerName,
    customerPhone: r.customerPhone,
    tableId: r.tableId,
    partySize: r.partySize,
    reservationDate: r.reservationDate,
    reservationTime: r.reservationTime,
    status: ReservationStatus.values.firstWhere(
      (e) => e.name == r.status,
      orElse: () => ReservationStatus.pending,
    ),
    notes: r.notes,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    handledBy: r.handledBy,
    rejectionReason: r.rejectionReason,
  );
}
