import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/providers.dart';
import '../../../domain/enums/payment_status.dart';

import '../../../domain/entities/staff.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';

/// Current logged in user provider derived from global auth state
final currentUserProvider = Provider<AsyncValue<Staff?>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  switch (authState.status) {
    case AuthStatus.loading:
      return const AsyncValue.loading();
    case AuthStatus.authenticated:
      return AsyncValue.data(authState.staff);
    case AuthStatus.error:
      return AsyncValue.error(authState.errorMessage ?? 'Auth Error', StackTrace.empty);
    default:
      return const AsyncValue.data(null);
  }
});

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
