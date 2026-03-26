import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uuid/uuid.dart';

import 'package:catsy_pos/data/local/providers.dart';
import 'package:catsy_pos/domain/entities/cafe_table.dart';
import 'package:catsy_pos/domain/enums/table_status.dart';
import 'package:catsy_pos/domain/repositories/table_repository.dart';

// ── Stream Provider ──────────────────────────────────────────────────────────

/// Watches all tables from the repository (reactive from SQLite).
final tablesProvider = StreamProvider<List<CafeTable>>((ref) {
  final repository = ref.watch(tableRepositoryProvider);
  return repository.watchTables();
});

// ── Controller for Table Actions ─────────────────────────────────────────────

/// State for table operations (creating, updating, deleting).
class TableController extends Notifier<AsyncValue<void>> {
  late final TableRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(tableRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<void> updateStatus(String tableId, TableStatus status) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateTableStatus(tableId, status);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> toggleStatus(String tableId) async {
    state = const AsyncValue.loading();
    final tablesResult = await _repository.getTables();
    final tables = tablesResult.getOrElse(() => []);
    final table = tables.firstWhere((t) => t.id == tableId);
    final nextStatus = table.status.next;
    final result = await _repository.updateTableStatus(tableId, nextStatus);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> addTable(String label, int capacity) async {
    state = const AsyncValue.loading();
    const uuid = Uuid();
    final newTable = CafeTable(
      id: uuid.v4(),
      label: label,
      capacity: capacity,
      status: TableStatus.available,
    );
    final result = await _repository.upsertTable(newTable);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> updateTable(CafeTable table) async {
    state = const AsyncValue.loading();
    final result = await _repository.upsertTable(table);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> deleteTable(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteTable(id);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> clearTable(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.clearTable(id);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }
}

/// Provider for the controller
final tableControllerProvider =
    NotifierProvider<TableController, AsyncValue<void>>(TableController.new);
