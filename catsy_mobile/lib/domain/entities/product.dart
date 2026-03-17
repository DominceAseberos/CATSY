import 'package:equatable/equatable.dart';

/// Menu product entity.
class Product extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String categoryId;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.categoryId,
    this.imageUrl,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, price, categoryId, isAvailable];
}
