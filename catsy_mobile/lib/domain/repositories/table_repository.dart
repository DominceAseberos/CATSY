import 'package:dartz/dartz.dart';
import 'package:catsy_pos/core/error/failures.dart';
import 'package:catsy_pos/domain/entities/cafe_table.dart';
import 'package:catsy_pos/domain/enums/table_status.dart';

/// Abstract contract for table management.
abstract class TableRepository {
  Stream<List<CafeTable>> watchTables();
  Future<Either<Failure, List<CafeTable>>> getTables();
  Future<Either<Failure, CafeTable>> getTableById(String id);
  Future<Either<Failure, void>> updateTableStatus(
    String id,
    TableStatus status,
  );
  Future<Either<Failure, void>> assignOrderToTable(
    String tableId,
    String orderId,
  );
  Future<Either<Failure, void>> clearTable(String tableId);
  Future<Either<Failure, void>> upsertTable(CafeTable table);
  Future<Either<Failure, void>> deleteTable(String id);
  Future<Either<Failure, void>> syncTables();
}
