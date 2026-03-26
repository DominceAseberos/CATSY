import 'package:catsy_pos/core/network/api_client.dart';
import 'package:catsy_pos/data/remote/dtos/customer_dto.dart';

/// Remote data source for customers.
class CustomerRemoteSource {
  final ApiClient _api;

  CustomerRemoteSource(this._api);

  Future<List<CustomerDto>> fetchAllCustomers() async {
    final data = await _api.get('/api/v1/customers') as List<dynamic>;
    return data
        .map((e) => CustomerDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CustomerDto>> fetchCustomersSince(DateTime since) async {
    final data =
        await _api.get(
              '/api/v1/customers',
              queryParams: {'updated_since': since.toIso8601String()},
            )
            as List<dynamic>;
    return data
        .map((e) => CustomerDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerDto?> fetchCustomerByQr(String qrCode) async {
    final data =
        await _api.get('/api/v1/customers/by-qr/$qrCode')
            as Map<String, dynamic>?;
    if (data == null) return null;
    return CustomerDto.fromJson(data);
  }

  Future<CustomerDto> upsertCustomer(Map<String, dynamic> body) async {
    final data =
        await _api.post('/api/v1/customers', body) as Map<String, dynamic>;
    return CustomerDto.fromJson(data);
  }

  Future<CustomerDto> addStamp(String customerId, int count) async {
    final data =
        await _api.post('/api/v1/customers/$customerId/stamps', {
              'stamps': count,
            })
            as Map<String, dynamic>;
    return CustomerDto.fromJson(data);
  }
}
