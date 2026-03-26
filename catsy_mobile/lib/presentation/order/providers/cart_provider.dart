import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:catsy_pos/domain/entities/addon.dart';
import 'package:catsy_pos/domain/entities/product.dart';

part 'cart_provider.freezed.dart';

// ── Cart Item ────────────────────────────────────────────────────────────────

/// A single line-item in the cart.
@freezed
abstract class CartItem with _$CartItem {
  const factory CartItem({
    required String id,
    required Product product,
    @Default(1) int quantity,
    @Default([]) List<Addon> addons,
  }) = _CartItem;

  const CartItem._();

  /// Base price for this line (product price × quantity).
  double get lineTotal =>
      (product.price + addons.fold(0.0, (sum, a) => sum + a.price)) * quantity;
}

// ── Cart State ───────────────────────────────────────────────────────────────

/// Immutable snapshot of the in-flight order being composed.
@freezed
abstract class CartState with _$CartState {
  const factory CartState({
    @Default([]) List<CartItem> items,
    String? customerId,
  }) = _CartState;

  const CartState._();

  // ── Computed getters ─────────────────────────────────────────────────

  static const double _taxRate = 0.12; // 12 % VAT

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get tax => subtotal * _taxRate;

  double get total => subtotal + tax;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

// ── Cart Notifier ────────────────────────────────────────────────────────────

const _uuid = Uuid();

/// Manages the mutable cart during an order session.
///
/// Each order session creates a fresh [CartState]. Call [clear] when the
/// order is placed or cancelled to reset back to an empty cart.
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  // ── Mutations ────────────────────────────────────────────────────────

  /// Adds [product] to the cart, with an optional [quantity] and [addons].
  ///
  /// If an identical line-item already exists (same product + same addons),
  /// the quantity is incremented instead of creating a duplicate.
  void addItem(
    Product product, {
    int quantity = 1,
    List<Addon>? addons,
  }) {
    final resolvedAddons = addons ?? const [];

    // Look for an existing matching line to merge quantities.
    final existingIndex = state.items.indexWhere(
      (it) =>
          it.product.id == product.id &&
          _addonsMatch(it.addons, resolvedAddons),
    );

    if (existingIndex != -1) {
      final updated = state.items.toList();
      updated[existingIndex] = updated[existingIndex].copyWith(
        quantity: updated[existingIndex].quantity + quantity,
      );
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(
            id: _uuid.v4(),
            product: product,
            quantity: quantity,
            addons: resolvedAddons,
          ),
        ],
      );
    }
  }

  /// Removes the line-item identified by [itemId].
  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((it) => it.id != itemId).toList(),
    );
  }

  /// Sets the [quantity] for an existing line-item.
  ///
  /// If [quantity] drops to 0, the item is removed automatically.
  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    state = state.copyWith(
      items: state.items.map((it) {
        return it.id == itemId ? it.copyWith(quantity: quantity) : it;
      }).toList(),
    );
  }

  /// Attaches a loyalty customer to this order session.
  void setCustomer(String? customerId) {
    state = state.copyWith(customerId: customerId);
  }

  /// Resets the cart to an empty state (call after order is submitted).
  void clear() {
    state = const CartState();
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  bool _addonsMatch(List<Addon> a, List<Addon> b) {
    if (a.length != b.length) return false;
    final aIds = a.map((e) => e.id).toSet();
    final bIds = b.map((e) => e.id).toSet();
    return aIds.containsAll(bIds);
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// Global cart provider.
///
/// Scoped to the lifetime of an order session — reset by calling
/// [CartNotifier.clear] when the order is finalised or abandoned.
final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);
