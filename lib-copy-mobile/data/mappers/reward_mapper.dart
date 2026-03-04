import '../../domain/entities/reward.dart';
import '../remote/dtos/reward_dto.dart';

class RewardMapper {
  static Reward fromDto(RewardDto dto) => Reward(
    id: dto.id,
    name: dto.name,
    description: dto.description,
    stampsRequired: dto.stampsRequired,
    isActive: dto.isActive,
    createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
    code: dto.code,
    customerId: dto.customerId,
    isClaimed: dto.isClaimed,
    claimedByStaffId: dto.claimedByStaffId,
    claimedAt: dto.claimedAt != null ? DateTime.tryParse(dto.claimedAt!) : null,
  );

  static RewardDto toDto(Reward entity) => RewardDto(
    id: entity.id,
    name: entity.name,
    description: entity.description,
    stampsRequired: entity.stampsRequired,
    isActive: entity.isActive,
    createdAt: entity.createdAt.toIso8601String(),
    code: entity.code,
    customerId: entity.customerId,
    isClaimed: entity.isClaimed,
    claimedByStaffId: entity.claimedByStaffId,
    claimedAt: entity.claimedAt?.toIso8601String(),
  );
}
