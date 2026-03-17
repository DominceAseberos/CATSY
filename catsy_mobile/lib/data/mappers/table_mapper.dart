import '../../domain/entities/cafe_table.dart';
import '../../domain/enums/table_status.dart';
import '../remote/dtos/table_dto.dart';

class TableMapper {
  static CafeTable fromDto(TableDto dto) => CafeTable(
    id: dto.id,
    label: dto.label,
    capacity: dto.capacity,
    status: TableStatus.values.firstWhere(
      (e) => e.name == dto.status,
      orElse: () => TableStatus.available,
    ),
    currentOrderId: dto.currentOrderId,
  );

  static TableDto toDto(CafeTable entity) => TableDto(
    id: entity.id,
    label: entity.label,
    capacity: entity.capacity,
    status: entity.status.name,
    currentOrderId: entity.currentOrderId,
    updatedAt: DateTime.now().toIso8601String(),
  );
}
