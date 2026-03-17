/// Whether the order is dine-in or take-out.
enum OrderType {
  dineIn,
  takeOut;

  String get label => switch (this) {
    OrderType.dineIn => 'Dine In',
    OrderType.takeOut => 'Take Out',
  };
}
