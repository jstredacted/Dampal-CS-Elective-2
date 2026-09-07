import 'package:flutter/foundation.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imagePath,
  });

  final int id;
  final String name;
  final double price;
  final String description;
  final String imagePath;
}

class CartItem {
  CartItem({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  double get subtotal => product.price * quantity;
}

const products = [
  Product(
    id: 1,
    name: 'Crimson Runner',
    price: 2499,
    description: 'A bright red running shoe with a soft and flexible sole.',
    imagePath: 'assets/images/shoe_1.jpg',
  ),
  Product(
    id: 2,
    name: 'Brown Street Low',
    price: 2899,
    description: 'A casual brown sneaker that is easy to match with outfits.',
    imagePath: 'assets/images/shoe_2.jpg',
  ),
  Product(
    id: 3,
    name: 'Classic White',
    price: 2199,
    description: 'A clean white shoe for school, errands, and daily wear.',
    imagePath: 'assets/images/shoe_3.jpg',
  ),
  Product(
    id: 4,
    name: 'Everyday White',
    price: 2699,
    description: 'A comfortable white sneaker with a simple classic style.',
    imagePath: 'assets/images/shoe_4.jpg',
  ),
  Product(
    id: 5,
    name: 'Midnight Trainer',
    price: 3199,
    description: 'A dark training shoe made for workouts and active days.',
    imagePath: 'assets/images/shoe_5.jpg',
  ),
  Product(
    id: 6,
    name: 'Cloud Runner',
    price: 2999,
    description: 'A light gray running shoe with soft cushioning for walking.',
    imagePath: 'assets/images/shoe_6.jpg',
  ),
];

class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  bool get isEmpty => _items.isEmpty;

  int get totalQuantity {
    int total = 0;
    for (final item in _items) {
      total += item.quantity;
    }
    return total;
  }

  double get total {
    double total = 0;
    for (final item in _items) {
      total += item.subtotal;
    }
    return total;
  }

  bool contains(Product product) {
    return _items.any((item) => item.product.id == product.id);
  }

  void add(Product product) {
    for (final item in _items) {
      if (item.product.id == product.id) {
        item.quantity++;
        notifyListeners();
        return;
      }
    }

    _items.add(CartItem(product: product));
    notifyListeners();
  }

  void decrease(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index == -1) {
      return;
    }

    _items[index].quantity--;
    if (_items[index].quantity == 0) {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
