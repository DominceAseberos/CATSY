import 'package:equatable/equatable.dart';
import 'package:catsy_pos/domain/enums/payment_method.dart';

/// Financial transaction record.
class TransactionRecord extends Equatable {
  final String id;
  final String orderId;
  final PaymentMethod paymentMethod;
  final double amount;
  final double? change;
  final DateTime transactedAt;

  const TransactionRecord({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.amount,
    this.change,
    required this.transactedAt,
  });

  @override
  List<Object?> get props => [id, orderId, amount];
}
