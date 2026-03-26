import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:catsy_pos/config/env.dart';
import 'package:catsy_pos/core/error/failures.dart';
import 'package:catsy_pos/core/utils/logger.dart';
import 'package:catsy_pos/data/local/secure_storage/secure_storage_service.dart';

/// HTTP client that wraps calls to the Catsy API Bridge server.
///
/// - Base URL is read from `.env` → `API_BRIDGE_BASE_URL`
/// - Auth token is injected from [SecureStorageService] automatically
/// - Non-2xx responses are mapped to [ServerFailure]
/// - SSL Pinning active in release builds
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
       _httpClient = httpClient ?? _createPinnedClient();

  // ── SSL Pinning Configuration ─────────────────────────────────────────
  static http.Client _createPinnedClient() {
    if (kDebugMode || Env.apiBridgeCertPem.isEmpty) {
      return http.Client();
    }
    try {
      final context = SecurityContext(withTrustedRoots: true);
      context.setTrustedCertificatesBytes(utf8.encode(Env.apiBridgeCertPem));
      final httpClient = HttpClient(context: context);
      return IOClient(httpClient);
    } catch (e) {
      AppLogger.e('[ApiClient] Warning: Failed to configure SSL Pinning — $e');
      return http.Client();
    }
  }

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

  // ── Token Refresh Logic ─────────────────────────────────────────────

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      AppLogger.i('[ApiClient] Attempting to refresh token...');
      final uri = _uri('/admin/refresh'); // API Bridge refresh endpoint
      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final newAccessToken = body['access_token'] as String?;
        final newRefreshToken = body['refresh_token'] as String?;

        if (newAccessToken != null) {
          await _storage.saveAuthToken(newAccessToken);
          if (newRefreshToken != null) {
            await _storage.saveRefreshToken(newRefreshToken);
          }
          AppLogger.i('[ApiClient] Token refreshed successfully.');
          return true;
        }
      }
    } catch (e) {
      AppLogger.e('[ApiClient] Token refresh failed: $e');
    }
    
    // Refresh failed entirely, force logout
    AppLogger.w('[ApiClient] Token refresh unrecoverable. Clearing session.');
    await _storage.clearAll(); // Clears staff ID and tokens; kicks to login
    return false;
  }

  // ── Network Wrapper ──────────────────────────────────────────────────

  Future<http.Response> _executeRequest({
    required Future<http.Response> Function(Map<String, String> headers) requestBuilder,
    required bool auth,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      var headers = await _headers(auth: auth);
      if (extraHeaders != null) headers.addAll(extraHeaders);

      var response = await requestBuilder(headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 && auth) {
        final success = await _tryRefreshToken();
        if (success) {
          // Retry original request exactly once
          headers = await _headers(auth: auth);
          if (extraHeaders != null) headers.addAll(extraHeaders);
          response = await requestBuilder(headers).timeout(const Duration(seconds: 15));
        }
      }

      return response;
    } on TimeoutException {
      AppLogger.e('[ApiClient] Request timed out');
      throw const ServerFailure(
        message: 'Request timed out after 15 seconds. Please check your connection.',
      );
    } on SocketException {
      AppLogger.e('[ApiClient] Socket exception (No Internet)');
      throw const ServerFailure(
        message: 'No internet connection. Please verify your network.',
      );
    } catch (e) {
      if (e is ServerFailure) rethrow; // Pass-through known failures
      AppLogger.e('[ApiClient] Unexpected error: $e');
      throw const ServerFailure(message: 'An unexpected network error occurred.');
    }
  }

  // ── Public HTTP methods ─────────────────────────────────────────────

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool auth = true,
  }) async {
    final uri = _uri(path, queryParams);
    final response = await _executeRequest(
      requestBuilder: (headers) => _httpClient.get(uri, headers: headers),
      auth: auth,
    );
    return _handleResponse(response, 'GET', path);
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final response = await _executeRequest(
      requestBuilder: (headers) => _httpClient.post(
        _uri(path),
        headers: headers,
        body: jsonEncode(body),
      ),
      auth: auth,
      extraHeaders: extraHeaders,
    );
    return _handleResponse(response, 'POST', path);
  }

  Future<dynamic> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final response = await _executeRequest(
      requestBuilder: (headers) => _httpClient.put(
        _uri(path), 
        headers: headers, 
        body: jsonEncode(body)
      ),
      auth: auth,
      extraHeaders: extraHeaders,
    );
    return _handleResponse(response, 'PUT', path);
  }

  Future<dynamic> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await _executeRequest(
      requestBuilder: (headers) => _httpClient.patch(
        _uri(path),
        headers: headers,
        body: jsonEncode(body),
      ),
      auth: auth,
    );
    return _handleResponse(response, 'PATCH', path);
  }

  Future<dynamic> delete(
    String path, {
    bool auth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final response = await _executeRequest(
      requestBuilder: (headers) => _httpClient.delete(_uri(path), headers: headers),
      auth: auth,
      extraHeaders: extraHeaders,
    );
    return _handleResponse(response, 'DELETE', path);
  }
}

// ── Providers ──────────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.read(secureStorageServiceProvider);
  return ApiClient(storage: storage);
});
