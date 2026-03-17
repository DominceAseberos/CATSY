import 'package:equatable/equatable.dart';

/// Customer entity (loyalty programme member).
class Customer extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? qrCode;
  final int totalStamps;
  final int rewardsRedeemed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.qrCode,
    this.totalStamps = 0,
    this.rewardsRedeemed = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, totalStamps];
}
