/// Lifecycle status of an order.
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  completed,
  cancelled;

  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.confirmed => 'Confirmed',
    OrderStatus.preparing => 'Preparing',
    OrderStatus.completed => 'Completed',
    OrderStatus.cancelled => 'Cancelled',
  };
}
