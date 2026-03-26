import 'package:catsy_pos/core/network/api_client.dart';
import 'package:catsy_pos/data/remote/dtos/order_dto.dart';

/// Remote data source for orders.
class OrderRemoteSource {
  final ApiClient _api;

  OrderRemoteSource(this._api);

  Future<List<OrderDto>> fetchAllOrders() async {
    final data = await _api.get('/api/v1/orders') as List<dynamic>;
    return data
        .map((e) => OrderDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderDto>> fetchOrdersSince(DateTime since) async {
    final data =
        await _api.get(
              '/api/v1/orders',
              queryParams: {'updated_since': since.toIso8601String()},
            )
            as List<dynamic>;
    return data
        .map((e) => OrderDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderDto> createOrder(Map<String, dynamic> body) async {
    final data =
        await _api.post('/api/v1/orders', body) as Map<String, dynamic>;
    return OrderDto.fromJson(data);
  }

  Future<OrderDto> updateOrder(String id, Map<String, dynamic> body) async {
    final data =
        await _api.put('/api/v1/orders/$id', body) as Map<String, dynamic>;
    return OrderDto.fromJson(data);
  }

  Future<void> deleteOrder(String id) => _api.delete('/api/v1/orders/$id');
}
