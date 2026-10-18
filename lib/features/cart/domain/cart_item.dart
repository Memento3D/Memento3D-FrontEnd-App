/// Frontend cart identity; [id] is not a backend product identifier.
class CartItem {
  CartItem({
    required this.id,
    required this.name,
    this.description,
    required this.unitPriceVnd,
    this.quantity = 1,
  }) {
    if (id.trim().isEmpty || name.trim().isEmpty) {
      throw ArgumentError('Cart identity and name must be nonempty');
    }
    if (unitPriceVnd < 0 || quantity < 1) {
      throw ArgumentError('Price must be nonnegative and quantity positive');
    }
  }
  final String id;
  final String name;
  final String? description;
  final int unitPriceVnd;
  final int quantity;
  int get totalVnd => unitPriceVnd * quantity;
  CartItem withQuantity(int quantity) => CartItem(
    id: id,
    name: name,
    description: description,
    unitPriceVnd: unitPriceVnd,
    quantity: quantity,
  );
}
