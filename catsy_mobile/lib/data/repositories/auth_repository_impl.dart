import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';

import '../../core/error/failures.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/staff.dart';
import '../../domain/repositories/auth_repository.dart';
import '../local/database/app_database.dart';
import '../local/database/daos/auth_dao.dart';
import '../local/secure_storage/secure_storage_service.dart';
import '../remote/sources/auth_remote_source.dart';
import '../../core/network/api_client.dart';

/// Phase 12 — tries API Bridge login first, falls back to local session.
class AuthRepositoryImpl implements AuthRepository {
  final AuthDao _authDao;
  final SecureStorageService _secureStorage;
  final ApiClient _apiClient;

  AuthRepositoryImpl({
    required AuthDao authDao,
    required SecureStorageService secureStorage,
    required ApiClient apiClient,
  }) : _authDao = authDao,
       _secureStorage = secureStorage,
       _apiClient = apiClient;

  // ── Fallback credentials (offline mode only) ─────────────────────────
  static const _offlineEmail = 'staff@cutsycafe.com';
  static const _offlinePassword = 'catsy123';
  static const _offlineStaffId = 'staff-001';
  static const _offlineStaffName = 'Test Staff';
  static const _offlineStaffRole = 'cashier';

  @override
  Future<Either<Failure, Staff>> login(String email, String password) async {
    // 1. Try online login against the API Bridge
    final isOnline = await ConnectivityService().isConnected;
    if (isOnline) {
      try {
        final remote = AuthRemoteSource(_apiClient);
        final tokenResponse = await remote.login(email, password);
        await _secureStorage.saveAuthToken(tokenResponse.accessToken);
        if (tokenResponse.refreshToken != null) {
          await _secureStorage.saveRefreshToken(tokenResponse.refreshToken!);
        }
        AppLogger.i('[Auth] API Bridge login succeeded');

        // Store staff profile (minimal, API Bridge doesn't return full profile)
        final now = DateTime.now();
        final staff = Staff(
          id: _offlineStaffId,
          name: email.split('@').first,
          email: email,
          role: 'cashier',
          createdAt: now,
          updatedAt: now,
        );
        await _authDao.saveStaffProfile(
          StaffTableCompanion(
            id: Value(staff.id),
            name: Value(staff.name),
            email: Value(staff.email),
            role: Value(staff.role),
            isActive: const Value(true),
            createdAt: Value(staff.createdAt),
            updatedAt: Value(staff.updatedAt),
          ),
        );
        await _secureStorage.saveStaffId(staff.id);
        return Right(staff);
      } catch (e) {
        AppLogger.w(
          '[Auth] API Bridge login failed: $e — trying offline fallback',
        );
      }
    }

    // 2. Offline fallback — validate against hardcoded credentials
    if (email != _offlineEmail || password != _offlinePassword) {
      return const Left(AuthFailure(message: 'Invalid email or password'));
    }

    try {
      final now = DateTime.now();
      final staff = Staff(
        id: _offlineStaffId,
        name: _offlineStaffName,
        email: _offlineEmail,
        role: _offlineStaffRole,
        createdAt: now,
        updatedAt: now,
      );
      await _authDao.saveStaffProfile(
        StaffTableCompanion(
          id: Value(staff.id),
          name: Value(staff.name),
          email: Value(staff.email),
          role: Value(staff.role),
          isActive: const Value(true),
          createdAt: Value(staff.createdAt),
          updatedAt: Value(staff.updatedAt),
        ),
      );
      await _secureStorage.saveAuthToken('offline-token-${staff.id}');
      await _secureStorage.saveStaffId(staff.id);
      AppLogger.i('[Auth] Offline login succeeded');
      return Right(staff);
    } catch (e) {
      return Left(CacheFailure(message: 'Login failed: $e'));
    }
  }

  @override
  Future<Either<Failure, Staff>> loginWithPin(String pin) async {
    try {
      return const Left(AuthFailure(message: 'PIN login not available yet'));
    } catch (e) {
      return Left(CacheFailure(message: 'Login with PIN failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final isOnline = await ConnectivityService().isConnected;
      if (isOnline) {
        try {
          await AuthRemoteSource(_apiClient).logout();
        } catch (_) {
          // best-effort
        }
      }
      await _authDao.clearStaffProfile();
      await _secureStorage.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Logout failed: $e'));
    }
  }

  @override
  Future<Either<Failure, Staff?>> getCurrentStaff() async {
    try {
      final row = await _authDao.getStaffProfile();
      if (row == null) return const Right(null);
      return Right(_mapToStaff(row));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get staff profile: $e'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  Staff _mapToStaff(StaffTableData row) => Staff(
    id: row.id,
    name: row.name,
    email: row.email,
    role: row.role,
    pin: row.pin,
    isActive: row.isActive,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
