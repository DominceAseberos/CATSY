/// Accepted payment methods.
enum PaymentMethod {
  cash,
  gcash,
  maya;

  String get label => switch (this) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.gcash => 'GCash',
    PaymentMethod.maya => 'Maya',
  };
}
