import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:catsy_pos/domain/entities/product.dart';
import 'package:catsy_pos/domain/entities/addon.dart';

class CartItem extends Equatable {
  final String id;
  final Product product;
  final int quantity;
  final List<Addon> addons;
  final String? notes;

  CartItem({
    String? id,
    required this.product,
    this.quantity = 1,
    this.addons = const [],
    this.notes,
  }) : id = id ?? const Uuid().v4();

  double get totalPrice {
    double addonsPrice = addons.fold(0, (sum, addon) => sum + addon.price);
    return (product.price + addonsPrice) * quantity;
  }

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    List<Addon>? addons,
    String? notes,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addons: addons ?? this.addons,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, product, quantity, addons, notes];
}
