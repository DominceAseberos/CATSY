import 'package:catsy_pos/domain/entities/customer.dart';
import 'package:catsy_pos/data/remote/dtos/customer_dto.dart';

class CustomerMapper {
  static Customer fromDto(CustomerDto dto) => Customer(
    id: dto.id,
    name: dto.name,
    email: dto.email,
    phone: dto.phone,
    qrCode: dto.qrCode,
    totalStamps: dto.totalStamps,
    rewardsRedeemed: dto.rewardsRedeemed,
    createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
    updatedAt: DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
  );

  static CustomerDto toDto(Customer entity) => CustomerDto(
    id: entity.id,
    name: entity.name,
    email: entity.email,
    phone: entity.phone,
    qrCode: entity.qrCode,
    totalStamps: entity.totalStamps,
    rewardsRedeemed: entity.rewardsRedeemed,
    createdAt: entity.createdAt.toIso8601String(),
    updatedAt: entity.updatedAt.toIso8601String(),
  );
}
