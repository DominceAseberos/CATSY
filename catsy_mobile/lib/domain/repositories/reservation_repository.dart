import 'package:dartz/dartz.dart';
import 'package:catsy_pos/core/error/failures.dart';
import 'package:catsy_pos/domain/entities/reservation.dart';

/// Abstract contract for reservation operations.
abstract class ReservationRepository {
  Future<Either<Failure, List<Reservation>>> getReservations();
  Future<Either<Failure, List<Reservation>>> getReservationsByDate(
    DateTime date,
  );
  Future<Either<Failure, Reservation>> getReservationById(String id);
  Future<Either<Failure, Reservation>> createReservation(
    Reservation reservation,
  );
  Future<Either<Failure, Reservation>> updateReservationStatus(
    String id,
    String status,
  );
  Future<Either<Failure, void>> syncReservations();
  Future<Either<Failure, Reservation>> approveReservation(
    String id,
    String staffId,
  );
  Future<Either<Failure, Reservation>> rejectReservation(
    String id,
    String staffId,
    String reason,
  );
}
