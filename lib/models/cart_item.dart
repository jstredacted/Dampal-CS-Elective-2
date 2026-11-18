import 'product.dart';

// One line in the cart: which product and how many of it.
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  // Only an estimate for the screen. The database recalculates the real
  // price when the order is placed.
  double get subtotal => product.price * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
