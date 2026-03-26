import 'package:equatable/equatable.dart';
import 'package:catsy_pos/domain/enums/reservation_status.dart';

/// Reservation entity.
class Reservation extends Equatable {
  final String id;
  final String customerName;
  final String? customerPhone;
  final String? tableId;
  final int partySize;
  final DateTime reservationDate;
  final DateTime reservationTime;
  final ReservationStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? handledBy;
  final String? rejectionReason;

  const Reservation({
    required this.id,
    required this.customerName,
    this.customerPhone,
    this.tableId,
    required this.partySize,
    required this.reservationDate,
    required this.reservationTime,
    this.status = ReservationStatus.pending,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.handledBy,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [
    id,
    customerName,
    reservationDate,
    status,
    handledBy,
    rejectionReason,
  ];
}
