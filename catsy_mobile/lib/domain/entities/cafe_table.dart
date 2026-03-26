import 'package:equatable/equatable.dart';
import 'package:catsy_pos/domain/enums/table_status.dart';

/// Physical café table entity.
class CafeTable extends Equatable {
  final String id;
  final String label; // e.g. "T1", "T2"
  final int capacity;
  final TableStatus status;
  final String? currentOrderId;

  const CafeTable({
    required this.id,
    required this.label,
    this.capacity = 4,
    this.status = TableStatus.available,
    this.currentOrderId,
  });

  @override
  List<Object?> get props => [id, label, status];
}
