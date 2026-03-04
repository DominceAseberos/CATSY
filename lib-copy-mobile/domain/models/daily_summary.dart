import 'package:equatable/equatable.dart';

/// Aggregate statistics for a single day's transactions.
class DailySummary extends Equatable {
  final double totalSales;
  final int orderCount;
  final Map<String, double> byPaymentMethod;

  const DailySummary({
    required this.totalSales,
    required this.orderCount,
    required this.byPaymentMethod,
  });

  factory DailySummary.empty() =>
      const DailySummary(totalSales: 0, orderCount: 0, byPaymentMethod: {});

  @override
  List<Object?> get props => [totalSales, orderCount, byPaymentMethod];
}
