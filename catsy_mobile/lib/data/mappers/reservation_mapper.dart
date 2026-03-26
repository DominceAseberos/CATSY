import 'package:catsy_pos/domain/entities/reservation.dart';
import 'package:catsy_pos/domain/enums/reservation_status.dart';
import 'package:catsy_pos/data/remote/dtos/reservation_dto.dart';

class ReservationMapper {
  static Reservation fromDto(ReservationDto dto) => Reservation(
    id: dto.id,
    customerName: dto.customerName,
    customerPhone: dto.customerPhone,
    tableId: dto.tableId,
    partySize: dto.partySize,
    reservationDate: DateTime.tryParse(dto.reservationDate) ?? DateTime.now(),
    reservationTime: DateTime.tryParse(dto.reservationTime) ?? DateTime.now(),
    status: ReservationStatus.values.firstWhere(
      (e) => e.name == dto.status,
      orElse: () => ReservationStatus.pending,
    ),
    notes: dto.notes,
    handledBy: dto.handledBy,
    rejectionReason: dto.rejectionReason,
    createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
    updatedAt: DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
  );

  static ReservationDto toDto(Reservation entity) => ReservationDto(
    id: entity.id,
    customerName: entity.customerName,
    customerPhone: entity.customerPhone,
    tableId: entity.tableId,
    partySize: entity.partySize,
    reservationDate: entity.reservationDate.toIso8601String(),
    reservationTime: entity.reservationTime.toIso8601String(),
    status: entity.status.name,
    notes: entity.notes,
    handledBy: entity.handledBy,
    rejectionReason: entity.rejectionReason,
    createdAt: entity.createdAt.toIso8601String(),
    updatedAt: entity.updatedAt.toIso8601String(),
  );
}
