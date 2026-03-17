import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/receipts_table.dart';

part 'receipt_dao.g.dart';

@DriftAccessor(tables: [ReceiptsTable])
class ReceiptDao extends DatabaseAccessor<AppDatabase> with _$ReceiptDaoMixin {
  ReceiptDao(super.db);

  Future<int> insertReceipt(ReceiptsTableCompanion receipt) =>
      into(receiptsTable).insert(receipt);

  Future<ReceiptsTableData?> getReceiptByOrderId(String orderId) => (select(
    receiptsTable,
  )..where((t) => t.orderId.equals(orderId))).getSingleOrNull();

  Future<ReceiptsTableData?> getReceiptByNumber(String receiptNumber) =>
      (select(
        receiptsTable,
      )..where((t) => t.receiptNumber.equals(receiptNumber))).getSingleOrNull();

  // Generate receipt number REC-YYYYMMDD-XXX
  Future<String> generateReceiptNumber() async {
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final countQuery = selectOnly(receiptsTable)
      ..addColumns([receiptsTable.id.count()])
      ..where(receiptsTable.generatedAt.isBetweenValues(startOfDay, endOfDay));

    final count = await countQuery
        .map((row) => row.read(receiptsTable.id.count()) ?? 0)
        .getSingle();

    final sequence = (count + 1).toString().padLeft(3, '0');
    return 'REC-$datePart-$sequence';
  }
}
