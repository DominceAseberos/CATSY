import 'package:catsy_pos/core/network/api_client.dart';
import 'package:catsy_pos/data/remote/dtos/table_dto.dart';

/// Remote data source for café tables.
class TableRemoteSource {
  final ApiClient _api;

  TableRemoteSource(this._api);

  Future<List<TableDto>> fetchAllTables() async {
    final data = await _api.get('/api/v1/tables') as List<dynamic>;
    return data
        .map((e) => TableDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TableDto>> fetchTablesSince(DateTime since) async {
    final data =
        await _api.get(
              '/api/v1/tables',
              queryParams: {'updated_since': since.toIso8601String()},
            )
            as List<dynamic>;
    return data
        .map((e) => TableDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TableDto> updateTable(String id, Map<String, dynamic> body) async {
    final data =
        await _api.put('/api/v1/tables/$id', body) as Map<String, dynamic>;
    return TableDto.fromJson(data);
  }

  /// Push a newly created table up to the cloud.
  Future<TableDto> createTable(TableDto table) async {
    final data = await _api.post('/api/v1/tables', {
      'label': table.label,
      'capacity': table.capacity,
      'status': table.status,
    }) as Map<String, dynamic>;
    return TableDto.fromJson(data);
  }

  /// Delete a table from the cloud.
  Future<void> deleteTable(String id) async {
    await _api.delete('/api/v1/tables/$id');
  }
}
