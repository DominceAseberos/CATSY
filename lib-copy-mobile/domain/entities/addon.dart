import 'package:equatable/equatable.dart';

/// Add-on entity (e.g. extra shot, whipped cream).
class Addon extends Equatable {
  final String id;
  final String name;
  final double price;
  final String productId;
  final bool isAvailable;

  const Addon({
    required this.id,
    required this.name,
    required this.price,
    this.productId = '',
    this.isAvailable = true,
  });

  @override
  List<Object?> get props => [id, name, price, isAvailable];
}
