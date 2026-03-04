import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';
import '../../data/local/secure_storage/secure_storage_service.dart';

/// HTTP client that wraps calls to the Catsy API Bridge server.
///
/// - Base URL is read from `.env` → `API_BRIDGE_BASE_URL`
/// - Auth token is injected from [SecureStorageService] automatically
/// - Non-2xx responses are mapped to [ServerFailure]
class ApiClient {
  final SecureStorageService _storage;
  final String _baseUrl;
  final http.Client _httpClient;

  ApiClient({
    required SecureStorageService storage,
    http.Client? httpClient,
    String? baseUrl,
  }) : _storage = storage,
       _baseUrl = baseUrl ?? Env.apiBridgeBaseUrl,
       _httpClient = httpClient ?? http.Client();

  // ── Header builder ──────────────────────────────────────────────────

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _storage.getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
      );
    }
    return uri;
  }

  // ── Response handler ────────────────────────────────────────────────

  dynamic _handleResponse(http.Response response, String method, String path) {
    AppLogger.d('[ApiClient] $method $path → ${response.statusCode}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    String message;
    try {
      final body = jsonDecode(response.body);
      message = body['detail']?.toString() ?? 'HTTP ${response.statusCode}';
    } catch (_) {
      message = 'HTTP ${response.statusCode}';
    }
    AppLogger.e('[ApiClient] Error: $message');
    throw ServerFailure(message: message);
  }

  // ── Public HTTP methods ─────────────────────────────────────────────

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool auth = true,
  }) async {
    final response = await _httpClient.get(
      _uri(path, queryParams),
      headers: await _headers(auth: auth),
    );
    return _handleResponse(response, 'GET', path);
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await _httpClient.post(
      _uri(path),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handleResponse(response, 'POST', path);
  }

  Future<dynamic> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await _httpClient.put(
      _uri(path),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handleResponse(response, 'PUT', path);
  }

  Future<dynamic> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await _httpClient.patch(
      _uri(path),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handleResponse(response, 'PATCH', path);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final response = await _httpClient.delete(
      _uri(path),
      headers: await _headers(auth: auth),
    );
    return _handleResponse(response, 'DELETE', path);
  }
}

// ── Providers ──────────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.read(secureStorageServiceProvider);
  return ApiClient(storage: storage);
});
