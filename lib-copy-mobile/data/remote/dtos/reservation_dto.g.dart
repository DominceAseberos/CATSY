// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReservationDto _$ReservationDtoFromJson(Map<String, dynamic> json) =>
    ReservationDto(
      id: json['id'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String?,
      tableId: json['table_id'] as String?,
      partySize: (json['party_size'] as num).toInt(),
      reservationDate: json['reservation_date'] as String,
      reservationTime: json['reservation_time'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      handledBy: json['handled_by'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$ReservationDtoToJson(ReservationDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customer_name': instance.customerName,
      'customer_phone': instance.customerPhone,
      'table_id': instance.tableId,
      'party_size': instance.partySize,
      'reservation_date': instance.reservationDate,
      'reservation_time': instance.reservationTime,
      'status': instance.status,
      'notes': instance.notes,
      'handled_by': instance.handledBy,
      'rejection_reason': instance.rejectionReason,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
