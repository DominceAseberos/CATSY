import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/providers.dart';
import '../../../domain/enums/payment_status.dart';

class User {
  final String? firstName;
  final String? lastName;
  User({this.firstName, this.lastName});
}

/// Current logged in user provider (placeholder)
final currentUserProvider = StreamProvider<User?>((ref) => Stream.value(null));

/// Restaurant open/close status provider
class RestaurantStatusNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
  void open() => state = true;
  void close() => state = false;
}

final restaurantOpenProvider = NotifierProvider<RestaurantStatusNotifier, bool>(
  RestaurantStatusNotifier.new,
);

/// Pending payments count - uses active orders with pending/hold status
final pendingPaymentsCountProvider = Provider<int>((ref) {
  final ordersAsync = ref.watch(activeOrdersProvider);
  final orders = ordersAsync.value ?? [];
  return orders
      .where(
        (o) =>
            o.paymentStatus == PaymentStatus.pending.name ||
            o.paymentStatus == PaymentStatus.hold.name,
      )
      .length;
});
