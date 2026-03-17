import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import '../app_database.dart';
import '../tables/orders_table.dart';
import '../tables/order_items_table.dart';
import '../tables/order_item_addons_table.dart';

part 'order_dao.g.dart';

@DriftAccessor(tables: [OrdersTable, OrderItemsTable, OrderItemAddonsTable])
class OrderDao extends DatabaseAccessor<AppDatabase> with _$OrderDaoMixin {
  OrderDao(super.db);

  // ── Watch ────────────────────────────────────────────────────────────
  Stream<List<OrdersTableData>> watchActiveOrders() =>
      (select(ordersTable)
            ..where((t) => t.status.isIn(['pending', 'confirmed', 'preparing']))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<int> watchTodayOrderCount() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final query = selectOnly(ordersTable)
      ..addColumns([ordersTable.id.count()])
      ..where(ordersTable.createdAt.isBetweenValues(start, end));
    return query
        .map((row) => row.read(ordersTable.id.count()) ?? 0)
        .watchSingle();
  }

  // ── Read ─────────────────────────────────────────────────────────────
  Future<OrdersTableData?> getOrderById(String id) =>
      (select(ordersTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<OrdersTableData>> getOrdersByStatus(String status) =>
      (select(ordersTable)..where((t) => t.status.equals(status))).get();

  Future<List<OrdersTableData>> getTodayOrders() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return (select(ordersTable)
          ..where((t) => t.createdAt.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<OrdersTableData>> getCompletedOrders({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) {
    final query = select(ordersTable)
      ..where((t) => t.status.equals('completed'))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit, offset: offset);
    if (dateFrom != null) {
      query.where((t) => t.createdAt.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null) {
      query.where((t) => t.createdAt.isSmallerOrEqualValue(dateTo));
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query.where((t) => t.id.like('%$searchQuery%'));
    }
    return query.get();
  }

  Stream<List<OrdersTableData>> watchCompletedOrders({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    final query = select(ordersTable)
      ..where((t) => t.status.equals('completed'))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (dateFrom != null) {
      query.where((t) => t.createdAt.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null) {
      query.where((t) => t.createdAt.isSmallerOrEqualValue(dateTo));
    }
    return query.watch();
  }

  /// Loads an order plus all its items and each item's add-ons in one call.
  Future<
    ({
      OrdersTableData? order,
      List<(OrderItemsTableData, List<OrderItemAddonsTableData>)>
      itemsWithAddons,
    })
  >
  getOrderWithItems(String orderId) async {
    final order = await getOrderById(orderId);
    final items = await getOrderItems(orderId);
    final itemsWithAddons =
        <(OrderItemsTableData, List<OrderItemAddonsTableData>)>[];
    for (final item in items) {
      final addons = await getOrderItemAddons(item.id);
      itemsWithAddons.add((item, addons));
    }
    return (order: order, itemsWithAddons: itemsWithAddons);
  }

  Future<List<OrderItemsTableData>> getOrderItems(String orderId) =>
      (select(orderItemsTable)..where((t) => t.orderId.equals(orderId))).get();

  Future<List<OrderItemAddonsTableData>> getOrderItemAddons(
    String orderItemId,
  ) => (select(
    orderItemAddonsTable,
  )..where((t) => t.orderItemId.equals(orderItemId))).get();

  // ── Write ───────────────────────────────────────────────────────────
  Future<void> insertOrder(OrdersTableCompanion order) =>
      into(ordersTable).insert(order);

  Future<void> insertOrderItems(List<OrderItemsTableCompanion> items) async {
    await batch((b) {
      b.insertAll(orderItemsTable, items);
    });
  }

  Future<void> insertOrderItemAddons(
    List<OrderItemAddonsTableCompanion> addons,
  ) async {
    await batch((b) {
      b.insertAll(orderItemAddonsTable, addons);
    });
  }

  Future<void> updateOrderStatus(String id, String status) =>
      (update(ordersTable)..where((t) => t.id.equals(id))).write(
        OrdersTableCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Generates a sequential order number for today: ORD-YYYYMMDD-XXX
  Future<String> generateOrderNumber() async {
    final today = DateTime.now();
    final datePart = DateFormat('yyyyMMdd').format(today);
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    final countQuery = selectOnly(ordersTable)
      ..addColumns([ordersTable.id.count()])
      ..where(ordersTable.createdAt.isBetweenValues(start, end));
    final count = await countQuery
        .map((r) => r.read(ordersTable.id.count()) ?? 0)
        .getSingle();

    final sequence = (count + 1).toString().padLeft(3, '0');
    return 'ORD-$datePart-$sequence';
  }
}
