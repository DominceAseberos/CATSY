/// Payment status for an order.
enum PaymentStatus {
  pending,
  hold,
  paid,
  refunded;

  String get label => switch (this) {
    PaymentStatus.pending => 'Pending',
    PaymentStatus.hold => 'On Hold',
    PaymentStatus.paid => 'Paid',
    PaymentStatus.refunded => 'Refunded',
  };
}
