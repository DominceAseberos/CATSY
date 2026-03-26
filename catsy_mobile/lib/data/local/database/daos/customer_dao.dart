import 'package:drift/drift.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/tables/customers_table.dart';
import 'package:catsy_pos/data/local/database/tables/loyalty_stamps_table.dart';

part 'customer_dao.g.dart';

@DriftAccessor(tables: [CustomersTable, LoyaltyStampsTable])
class CustomerDao extends DatabaseAccessor<AppDatabase>
    with _$CustomerDaoMixin {
  CustomerDao(super.db);

  // ── Read ─────────────────────────────────────────────────────────────
  Future<CustomersTableData?> getCustomerById(String id) =>
      (select(customersTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<CustomersTableData?> getCustomerByQRCode(String qrCode) => (select(
    customersTable,
  )..where((t) => t.qrCode.equals(qrCode))).getSingleOrNull();

  Future<List<CustomersTableData>> searchCustomers(String query) =>
      (select(customersTable)
            ..where(
              (t) =>
                  t.name.like('%$query%') |
                  t.email.like('%$query%') |
                  t.phone.like('%$query%'),
            )
            ..limit(20))
          .get();

  // ── Stamps ──────────────────────────────────────────────────────────
  Future<void> updateStamps(String customerId, int newCount) =>
      (update(customersTable)..where((t) => t.id.equals(customerId))).write(
        CustomersTableCompanion(
          totalStamps: Value(newCount),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> insertStampLog(LoyaltyStampsTableCompanion stampLog) =>
      into(loyaltyStampsTable).insert(stampLog);

  Future<List<LoyaltyStampsTableData>> getStampLogs(String customerId) =>
      (select(loyaltyStampsTable)
            ..where((t) => t.customerId.equals(customerId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  // ── Write ───────────────────────────────────────────────────────────
  Future<void> upsertCustomer(CustomersTableCompanion customer) =>
      into(customersTable).insertOnConflictUpdate(customer);
}
