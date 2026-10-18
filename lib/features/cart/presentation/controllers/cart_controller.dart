import 'package:flutter/foundation.dart';

import '../../domain/cart.dart';
import '../../domain/cart_item.dart';

class CartController extends ChangeNotifier {
  Cart _cart = Cart();
  Cart get cart => _cart;

  void _replace(Iterable<CartItem> items) {
    _cart = Cart(items);
    notifyListeners();
  }

  /// Same identity merges quantities. Conflicting metadata is rejected so that
  /// an old price or a different configuration cannot silently replace an item.
  void addItem(CartItem item) {
    final index = _cart.items.indexWhere((entry) => entry.id == item.id);
    if (index < 0) {
      _replace([..._cart.items, item]);
      return;
    }
    final existing = _cart.items[index];
    if (existing.name != item.name ||
        existing.description != item.description ||
        existing.unitPriceVnd != item.unitPriceVnd) {
      throw ArgumentError('Conflicting cart item identity');
    }
    updateQuantity(item.id, existing.quantity + item.quantity);
  }

  void removeItem(String id) {
    if (!_cart.items.any((item) => item.id == id)) return;
    _replace(_cart.items.where((item) => item.id != id));
  }

  void updateQuantity(String id, int quantity) {
    if (quantity < 1) throw ArgumentError.value(quantity, 'quantity');
    if (!_cart.items.any((item) => item.id == id && item.quantity != quantity)) {
      return;
    }
    _replace(
      _cart.items.map(
        (item) => item.id == id ? item.withQuantity(quantity) : item,
      ),
    );
  }

  void increaseQuantity(String id) {
    for (final item in _cart.items) {
      if (item.id == id) {
        updateQuantity(id, item.quantity + 1);
        return;
      }
    }
  }

  /// Decreasing from one removes the item.
  void decreaseQuantity(String id) {
    for (final item in _cart.items) {
      if (item.id == id) {
        if (item.quantity == 1) {
          removeItem(id);
        } else {
          updateQuantity(id, item.quantity - 1);
        }
        return;
      }
    }
  }

  void clear() {
    if (!_cart.isEmpty) _replace(const []);
  }
}
