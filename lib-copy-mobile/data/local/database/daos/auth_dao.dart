import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/staff_table.dart';

part 'auth_dao.g.dart';

@DriftAccessor(tables: [StaffTable])
class AuthDao extends DatabaseAccessor<AppDatabase> with _$AuthDaoMixin {
  AuthDao(super.db);

  // ── Read ─────────────────────────────────────────────────────────────
  Future<StaffTableData?> getStaffProfile() =>
      (select(staffTable)..limit(1)).getSingleOrNull();

  Future<StaffTableData?> getStaffByEmail(String email) => (select(
    staffTable,
  )..where((t) => t.email.equals(email))).getSingleOrNull();

  Future<StaffTableData?> getStaffById(String id) =>
      (select(staffTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ── Write ───────────────────────────────────────────────────────────
  Future<void> saveStaffProfile(StaffTableCompanion staff) =>
      into(staffTable).insertOnConflictUpdate(staff);

  /// Clears all staff data (logout).
  Future<void> clearStaffProfile() => delete(staffTable).go();
}
