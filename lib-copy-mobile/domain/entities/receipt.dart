import 'package:equatable/equatable.dart';

/// Receipt entity for printing / display.
class Receipt extends Equatable {
  final String id;
  final String orderId;
  final String content; // pre-formatted receipt text
  final DateTime generatedAt;

  const Receipt({
    required this.id,
    required this.orderId,
    required this.content,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [id, orderId];
}
