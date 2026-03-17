/// Status of a café table.
enum TableStatus {
  available,
  reserved,
  occupied,
  billReady;

  String get label => switch (this) {
    TableStatus.available => 'Available',
    TableStatus.reserved => 'Reserved',
    TableStatus.occupied => 'Occupied',
    TableStatus.billReady => 'Bill Ready',
  };

  /// Returns the next status when tapping (cyclic)
  TableStatus get next => switch (this) {
    TableStatus.available => TableStatus.occupied,
    TableStatus.occupied => TableStatus.billReady,
    TableStatus.billReady => TableStatus.available,
    TableStatus.reserved => TableStatus.occupied,
  };
}
