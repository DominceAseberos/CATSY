import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catsy_pos/domain/entities/inventory_item.dart';
import 'package:catsy_pos/data/local/providers.dart';

// ── State ────────────────────────────────────────────────────────────────────

class LowStockOnly extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final lowStockOnlyProvider = NotifierProvider<LowStockOnly, bool>(
  LowStockOnly.new,
);

// ── Stream Providers ─────────────────────────────────────────────────────────

final inventoryListProvider = StreamProvider<List<InventoryItem>>((ref) async* {
  final repository = ref.watch(inventoryRepositoryProvider);
  final lowStockOnly = ref.watch(lowStockOnlyProvider);

  final stream = repository.watchInventory();

  await for (final items in stream) {
    if (lowStockOnly) {
      yield items.where((i) => i.isLowStock).toList();
    } else {
      yield items;
    }
  }
});

final inventoryMapProvider = Provider<Map<String, int>>((ref) {
  final inventoryListAsync = ref.watch(inventoryListProvider);
  final inventoryList = inventoryListAsync.asData?.value ?? [];
  return {for (var item in inventoryList) item.productId: item.currentStock};
});

final lowStockAlertCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchLowStockCount();
});

// ── Controller for Actions ───────────────────────────────────────────────────

class InventoryController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> updateStock(String productId, int newStock) async {
    state = const AsyncValue.loading();
    final repository = ref.read(inventoryRepositoryProvider);
    final result = await repository.updateStock(productId, newStock);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> deductStock(String productId, int quantity) async {
    state = const AsyncValue.loading();
    final repository = ref.read(inventoryRepositoryProvider);
    final result = await repository.deductStock(productId, quantity);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }
}

final inventoryControllerProvider =
    NotifierProvider<InventoryController, AsyncValue<void>>(
      InventoryController.new,
    );
