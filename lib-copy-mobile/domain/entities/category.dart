import 'package:equatable/equatable.dart';

/// Menu category entity.
class Category extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int sortOrder;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, sortOrder];
}
