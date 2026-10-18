import 'cart_item.dart';
import '../../payment/domain/payment.dart';

/// Immutable snapshot. Item count is the sum of quantities.
class Cart {
  Cart([Iterable<CartItem> items = const []])
    : items = List.unmodifiable(items) {
    if (this.items.map((item) => item.id).toSet().length != this.items.length) {
      throw ArgumentError('Duplicate cart identities');
    }
  }
  final List<CartItem> items;
  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  int get subtotalVnd => items.fold(0, (sum, item) => sum + item.totalVnd);
  int get totalVnd => subtotalVnd;

  CheckoutSummary toCheckoutSummary() {
    if (isEmpty) throw StateError('Cannot check out an empty cart');
    return CheckoutSummary(
      subtotal: Money(subtotalVnd),
      serviceFee: const Money(0),
      items: List.unmodifiable(
        items.map(
          (item) => CheckoutLine(
            name: item.name,
            description: item.description,
            quantity: item.quantity,
            unitPrice: Money(item.unitPriceVnd),
          ),
        ),
      ),
    );
  }
}
