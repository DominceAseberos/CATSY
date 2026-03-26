import 'package:drift/drift.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/tables/transactions_table.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  // ── Watch ────────────────────────────────────────────────────────────
  Stream<List<TransactionsTableData>> watchTodayTransactions() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return (select(transactionsTable)
          ..where((t) => t.transactedAt.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.transactedAt)]))
        .watch();
  }

  // ── Read ─────────────────────────────────────────────────────────────
  Future<List<TransactionsTableData>> getAllTransactions({
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 20,
    int offset = 0,
  }) {
    final query = select(transactionsTable)
      ..orderBy([(t) => OrderingTerm.desc(t.transactedAt)])
      ..limit(limit, offset: offset);
    if (dateFrom != null) {
      query.where((t) => t.transactedAt.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null) {
      query.where((t) => t.transactedAt.isSmallerOrEqualValue(dateTo));
    }
    return query.get();
  }

  /// Returns (totalSales, transactionCount) for a given date.
  Future<({double totalSales, int count})> getDailySummary(
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await (select(
      transactionsTable,
    )..where((t) => t.transactedAt.isBetweenValues(start, end))).get();
    final totalSales = rows.fold<double>(0, (sum, t) => sum + t.amount);
    return (totalSales: totalSales, count: rows.length);
  }

  Future<TransactionsTableData?> getTransactionForOrder(String orderId) =>
      (select(
        transactionsTable,
      )..where((t) => t.orderId.equals(orderId))).getSingleOrNull();

  /// Returns total sales grouped by payment method for a given date.
  Future<Map<String, double>> getDailySummaryByPaymentMethod(
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await (select(
      transactionsTable,
    )..where((t) => t.transactedAt.isBetweenValues(start, end))).get();
    final breakdown = <String, double>{};
    for (final row in rows) {
      breakdown[row.paymentMethod] =
          (breakdown[row.paymentMethod] ?? 0) + row.amount;
    }
    return breakdown;
  }

  // ── Write ───────────────────────────────────────────────────────────
  Future<void> insertTransaction(TransactionsTableCompanion transaction) =>
      into(transactionsTable).insert(transaction);
}
