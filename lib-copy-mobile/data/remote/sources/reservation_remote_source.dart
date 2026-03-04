import '../../../core/network/api_client.dart';
import '../dtos/reservation_dto.dart';

class ReservationRemoteSource {
  final ApiClient _api;

  ReservationRemoteSource(this._api);

  Future<List<ReservationDto>> fetchAllReservations() async {
    final data = await _api.get('/api/staff/reservations') as List<dynamic>;
    return data
        .map((e) => ReservationDto.fromJson(_mapReservation(e as Map<String, dynamic>)))
        .toList();
  }

  Future<List<ReservationDto>> fetchReservationsSince(DateTime since) async {
    final data =
        await _api.get(
              '/api/staff/reservations',
              queryParams: {'updated_since': since.toIso8601String()},
            )
            as List<dynamic>;
    return data
        .map((e) => ReservationDto.fromJson(_mapReservation(e as Map<String, dynamic>)))
        .toList();
  }

  Future<ReservationDto> createReservation(Map<String, dynamic> body) async {
    final data =
        await _api.post('/api/staff/reservations', body) as Map<String, dynamic>;
    return ReservationDto.fromJson(_mapReservation(data));
  }

  Future<ReservationDto> updateReservation(
    String id,
    Map<String, dynamic> body,
  ) async {
    final data =
        await _api.patch('/api/staff/reservations/$id', body)
            as Map<String, dynamic>;
    return ReservationDto.fromJson(_mapReservation(data));
  }

  Map<String, dynamic> _mapReservation(Map<String, dynamic> api) {
    return {
      'id': api['id']?.toString(),
      'customer_name': api['customer_name'] ?? api['name'],
      'customer_phone': api['customer_phone'] ?? api['phone'],
      'table_id': api['table_id']?.toString(),
      'party_size': api['party_size'] ?? api['guests'] ?? 1,
      'reservation_date': api['reservation_date'] ?? api['date'],
      'reservation_time': api['reservation_time'] ?? api['time'],
      'status': api['status'] ?? 'pending',
      'notes': api['notes'],
      'handled_by': api['handled_by']?.toString(),
      'rejection_reason': api['rejection_reason'],
      'created_at': api['created_at'],
      'updated_at': api['updated_at'],
    };
  }
}
