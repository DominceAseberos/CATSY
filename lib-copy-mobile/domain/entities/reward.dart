import 'package:equatable/equatable.dart';

/// Reward that a customer can claim.
class Reward extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int stampsRequired;
  final bool isActive;
  final DateTime createdAt;

  // ── Phase 9: Claim fields ─────────────────────────────────────────────
  /// Unique claim code (printed on receipt or shown as QR).
  final String? code;

  /// Customer this reward belongs to.
  final String? customerId;

  /// Whether the reward has been claimed.
  final bool isClaimed;

  /// Staff who processed the claim.
  final String? claimedByStaffId;

  /// Timestamp when the claim was processed.
  final DateTime? claimedAt;

  const Reward({
    required this.id,
    required this.name,
    this.description,
    required this.stampsRequired,
    this.isActive = true,
    required this.createdAt,
    // Phase 9 fields
    this.code,
    this.customerId,
    this.isClaimed = false,
    this.claimedByStaffId,
    this.claimedAt,
  });

  @override
  List<Object?> get props => [id, name, stampsRequired, isClaimed];
}
