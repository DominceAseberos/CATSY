import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Secure storage service for tokens, session data, PINs, etc.
class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Keys ──────────────────────────────────────────────────────────────
  static const _keyAuthToken = 'auth_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyStaffId = 'staff_id';
  static const _keyStaffPin = 'staff_pin';
  static const _keyLastSyncTimestamp = 'last_sync_timestamp';

  // ── Auth Token ────────────────────────────────────────────────────────
  Future<void> saveAuthToken(String token) =>
      _storage.write(key: _keyAuthToken, value: token);

  Future<String?> getAuthToken() => _storage.read(key: _keyAuthToken);

  Future<void> deleteAuthToken() => _storage.delete(key: _keyAuthToken);

  // ── Refresh Token ─────────────────────────────────────────────────────
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _keyRefreshToken, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  // ── Staff ─────────────────────────────────────────────────────────────
  Future<void> saveStaffId(String id) =>
      _storage.write(key: _keyStaffId, value: id);

  Future<String?> getStaffId() => _storage.read(key: _keyStaffId);

  Future<void> saveStaffPin(String pin) =>
      _storage.write(key: _keyStaffPin, value: pin);

  Future<String?> getStaffPin() => _storage.read(key: _keyStaffPin);

  // ── Clear All ─────────────────────────────────────────────────────────
  Future<void> clearAll() => _storage.deleteAll();

  // ── Last Sync Timestamp ─────────────────────────────────────────────
  Future<void> saveLastSyncTimestamp(DateTime timestamp) => _storage.write(
    key: _keyLastSyncTimestamp,
    value: timestamp.toIso8601String(),
  );

  Future<DateTime?> getLastSyncTimestamp() async {
    final raw = await _storage.read(key: _keyLastSyncTimestamp);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}

// ── Provider ─────────────────────────────────────────────────────────────
final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);
