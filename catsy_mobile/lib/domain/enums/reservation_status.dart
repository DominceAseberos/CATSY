/// Reservation approval status.
enum ReservationStatus {
  pending,
  approved,
  rejected,
  cancelled,
  completed;

  String get label => switch (this) {
    ReservationStatus.pending => 'Pending',
    ReservationStatus.approved => 'Approved',
    ReservationStatus.rejected => 'Rejected',
    ReservationStatus.cancelled => 'Cancelled',
    ReservationStatus.completed => 'Completed',
  };
}
