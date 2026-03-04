import 'package:equatable/equatable.dart';

/// A single loyalty stamp event.
class LoyaltyStamp extends Equatable {
  final String id;
  final String customerId;
  final String orderId;
  final String staffId;
  final int stampsAdded;
  final DateTime createdAt;

  const LoyaltyStamp({
    required this.id,
    required this.customerId,
    required this.orderId,
    required this.staffId,
    this.stampsAdded = 1,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, customerId, orderId];
}
