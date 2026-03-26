import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';

import 'package:flutter/foundation.dart';
import 'package:catsy_pos/core/error/failures.dart';
import 'package:catsy_pos/core/network/connectivity_service.dart';
import 'package:catsy_pos/core/utils/logger.dart';
import 'package:catsy_pos/domain/entities/staff.dart';
import 'package:catsy_pos/domain/repositories/auth_repository.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/daos/auth_dao.dart';
import 'package:catsy_pos/data/local/secure_storage/secure_storage_service.dart';
import 'package:catsy_pos/data/remote/sources/auth_remote_source.dart';
import 'package:catsy_pos/core/network/api_client.dart';

/// Phase 12 — tries API Bridge login first, falls back to local session.
class AuthRepositoryImpl implements AuthRepository {
  final AuthDao _authDao;
  final SecureStorageService _secureStorage;
  final ApiClient _apiClient;
  final ConnectivityService _connectivity;

  AuthRepositoryImpl({
    required AuthDao authDao,
    required SecureStorageService secureStorage,
    required ApiClient apiClient,
    required ConnectivityService connectivity,
  }) : _authDao = authDao,
       _secureStorage = secureStorage,
       _apiClient = apiClient,
       _connectivity = connectivity;

  @override
  Future<Either<Failure, Staff>> login(String email, String password) async {
    // 1. Try online login against the API Bridge
    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      try {
        final remote = AuthRemoteSource(_apiClient);
        final tokenResponse = await remote.login(email, password);
        await _secureStorage.saveAuthToken(tokenResponse.accessToken);
        if (tokenResponse.refreshToken != null) {
          await _secureStorage.saveRefreshToken(tokenResponse.refreshToken!);
        }
        AppLogger.i('[Auth] API Bridge login succeeded');

        // Store staff profile (using email as ID since no userId is returned from API Bridge)
        final now = DateTime.now();
        final staffId = email;
        final staff = Staff(
          id: staffId,
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

    // 2. Offline fallback — validate against cached session
    try {
      // Dev-only offline shortcut
      if (kDebugMode && email == 'staff@cutsycafe.com' && password == 'catsy123') {
        final now = DateTime.now();
        final staff = Staff(
          id: 'dev-staff-001',
          name: 'Dev Staff',
          email: 'staff@cutsycafe.com',
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
        await _secureStorage.saveAuthToken('offline-dev-token');
        await _secureStorage.saveStaffId(staff.id);
        AppLogger.i('[Auth] Offline Dev login succeeded');
        return Right(staff);
      }

      final cachedToken = await _secureStorage.getAuthToken();
      final cachedStaffId = await _secureStorage.getStaffId();
      
      if (cachedToken != null && cachedStaffId != null) {
        final staffRow = await _authDao.getStaffProfile();
        // Return success if there is a cached session for the requested email
        if (staffRow != null && staffRow.email == email) {
          AppLogger.i('[Auth] Offline cached session login succeeded');
          return Right(_mapToStaff(staffRow));
        }
      }
      
      return const Left(AuthFailure(message: 'You must log in online at least once'));
    } catch (e) {
      return Left(CacheFailure(message: 'Offline login failed: $e'));
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
      final isOnline = await _connectivity.isConnected;
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
