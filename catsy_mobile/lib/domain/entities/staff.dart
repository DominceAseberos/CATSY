import 'package:equatable/equatable.dart';

/// Staff member entity.
class Staff extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role; // e.g. 'cashier', 'barista', 'manager'
  final String? pin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Staff({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.pin,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, email, role, pin, isActive];
}
