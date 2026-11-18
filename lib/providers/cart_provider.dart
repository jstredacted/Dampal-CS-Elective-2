import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import 'user_provider.dart';

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

// The cart lives in app state, so it stays the same while the user moves
// between screens.
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    // Empty the cart when the user signs out or a different user signs in.
    ref.listen(currentUserProvider.select((user) => user?.id), (prev, next) {
      if (prev != next) state = [];
    });
    return [];
  }

  int quantityOf(int productId) {
    for (final item in state) {
      if (item.product.id == productId) return item.quantity;
    }
    return 0;
  }

  // Returns an error message, or null when the product was added.
  String? add(Product product) {
    if (product.stock <= 0) return '${product.name} is out of stock.';
    final current = quantityOf(product.id);
    if (current >= product.stock) {
      return 'Only ${product.stock} of ${product.name} available.';
    }
    if (current == 0) {
      state = [...state, CartItem(product: product, quantity: 1)];
    } else {
      setQuantity(product.id, current + 1);
    }
    return null;
  }

  // Returns an error message when the quantity is above the stock.
  String? setQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return null;
    }
    final item = state.firstWhere((item) => item.product.id == productId);
    if (quantity > item.product.stock) {
      return 'Only ${item.product.stock} of ${item.product.name} available.';
    }
    // A new list (instead of changing the old one) tells Riverpod to rebuild.
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(quantity: quantity)
        else
          item,
    ];
    return null;
  }

  void remove(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clear() {
    state = [];
  }
}

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0.0, (sum, item) => sum + item.subtotal);
});
