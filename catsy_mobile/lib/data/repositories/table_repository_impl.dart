import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../../data/remote/dtos/table_dto.dart';
import '../../data/remote/sources/table_remote_source.dart';
import '../../domain/entities/cafe_table.dart';
import '../../domain/enums/table_status.dart';
import '../../domain/repositories/table_repository.dart';
import '../local/database/daos/table_dao.dart';
import '../local/database/app_database.dart';

/// Phase 2 — LOCAL + REMOTE sync. Uses TableDao (local) and TableRemoteSource (remote).
class TableRepositoryImpl implements TableRepository {
  final TableDao _tableDao;
  final ApiClient? _apiClient;

  TableRepositoryImpl({required TableDao tableDao, ApiClient? apiClient})
      : _tableDao = tableDao,
        _apiClient = apiClient;

  @override
  Stream<List<CafeTable>> watchTables() {
    return _tableDao.watchAllTables().map(
      (rows) => rows.map(_mapToTable).toList(),
    );
  }

  @override
  Future<Either<Failure, List<CafeTable>>> getTables() async {
    try {
      final rows = await _tableDao.getAllTables();
      return Right(rows.map(_mapToTable).toList());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get tables: $e'));
    }
  }

  @override
  Future<Either<Failure, CafeTable>> getTableById(String id) async {
    try {
      final row = await _tableDao.getTableById(id);
      if (row == null) {
        return const Left(CacheFailure(message: 'Table not found'));
      }
      return Right(_mapToTable(row));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get table: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTableStatus(
    String id,
    TableStatus status,
  ) async {
    try {
      await _tableDao.updateTableStatus(id, status.name);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to update table status: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> assignOrderToTable(
    String tableId,
    String orderId,
  ) async {
    try {
      await _tableDao.assignOrder(tableId, orderId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to assign order: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearTable(String tableId) async {
    try {
      await _tableDao.clearTable(tableId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear table: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> upsertTable(CafeTable table) async {
    try {
      // 1. Always save to local DB first (offline-first)
      await _tableDao.upsertTable(
        CafeTablesTableCompanion(
          id: Value(table.id),
          label: Value(table.label),
          capacity: Value(table.capacity),
          status: Value(table.status.name),
          currentOrderId: Value(table.currentOrderId),
        ),
      );

      // 2. If online, push to remote (fire-and-forget — don't block local success)
      if (_apiClient != null) {
        unawaited(TableRemoteSource(_apiClient)
            .createTable(
              TableDto(
                id: table.id,
                label: table.label,
                capacity: table.capacity,
                status: table.status.name,
                currentOrderId: table.currentOrderId,
              ),
            )
            .catchError((e) => throw Exception('[TableRepo] Remote create failed: $e')));
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to upsert table: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTable(String id) async {
    try {
      // 1. Delete locally first
      await _tableDao.deleteTable(id);

      // 2. If online, delete from remote too (fire-and-forget)
      if (_apiClient != null) {
        unawaited(TableRemoteSource(_apiClient)
            .deleteTable(id)
            .catchError((e) => throw Exception('[TableRepo] Remote delete failed: $e')));
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to delete table: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncTables() async {
    // Phase 1: No-op
    return const Right(null);
  }

  CafeTable _mapToTable(CafeTablesTableData r) {
    return CafeTable(
      id: r.id,
      label: r.label,
      capacity: r.capacity,
      status: TableStatus.values.firstWhere(
        (e) => e.name == r.status,
        orElse: () => TableStatus.available,
      ),
      currentOrderId: r.currentOrderId,
    );
  }
}
