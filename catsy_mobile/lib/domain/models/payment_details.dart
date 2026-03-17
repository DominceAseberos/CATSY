import '../enums/payment_method.dart';

class PaymentDetails {
  final PaymentMethod method;
  final double? amountTendered; // For cash
  final String? referenceId; // For digital

  const PaymentDetails({
    required this.method,
    this.amountTendered,
    this.referenceId,
  });
}
