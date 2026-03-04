import 'package:drift/drift.dart';

class RewardsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get stampsRequired => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  // ── Phase 9: Claim fields ─────────────────────────────────────────────
  /// Human-readable or QR-encoded claim code. Nullable for backward compat.
  TextColumn get code => text().nullable()();

  /// The customer this reward belongs to. Nullable for generic/template rewards.
  TextColumn get customerId => text().nullable()();

  /// Whether this specific reward instance has been claimed.
  BoolColumn get isClaimed => boolean().withDefault(const Constant(false))();

  /// Staff who processed the claim.
  TextColumn get claimedByStaffId => text().nullable()();

  /// When the reward was claimed.
  DateTimeColumn get claimedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
