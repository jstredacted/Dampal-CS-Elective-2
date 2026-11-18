import 'dart:async';

import 'package:dampal_cs_elective_2/models/cart_item.dart';
import 'package:dampal_cs_elective_2/models/category.dart';
import 'package:dampal_cs_elective_2/models/order.dart';
import 'package:dampal_cs_elective_2/models/product.dart';
import 'package:dampal_cs_elective_2/models/product_filter.dart';
import 'package:dampal_cs_elective_2/models/product_page.dart';
import 'package:dampal_cs_elective_2/models/profile.dart';
import 'package:dampal_cs_elective_2/pages/auth_gate.dart';
import 'package:dampal_cs_elective_2/providers/category_provider.dart';
import 'package:dampal_cs_elective_2/providers/order_provider.dart';
import 'package:dampal_cs_elective_2/providers/product_provider.dart';
import 'package:dampal_cs_elective_2/providers/user_provider.dart';
import 'package:dampal_cs_elective_2/services/auth_service.dart';
import 'package:dampal_cs_elective_2/services/order_service.dart';
import 'package:dampal_cs_elective_2/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const categories = [
  Category(id: 1, name: 'Running'),
  Category(id: 2, name: 'Skate'),
];

// Products 1-21. Odd ids are Running, even ids are Skate.
// Prices go up by ₱500: Shoe 1 = ₱500, Shoe 21 = ₱10,500.
// Stock equals the id: Shoe 1 has 1 pair, Shoe 2 has 2 pairs, and so on.
List<Product> sampleProducts() => [
  for (var i = 1; i <= 21; i++)
    Product(
      id: i,
      name: 'Shoe $i',
      description: 'Description $i',
      price: i * 500,
      stock: i,
      imageUrl: '',
      categoryId: i.isOdd ? 1 : 2,
    ),
];

// Works like the Supabase query, but on a list in memory.
class FakeProductService implements ProductService {
  FakeProductService(this.products);

  final List<Product> products;
  final List<ProductFilter> requests = [];
  int _nextId = 100;

  @override
  Future<ProductPage> fetchProducts(ProductFilter filter) async {
    requests.add(filter);
    final term = filter.search.trim().toLowerCase();
    final matches = products.where((p) {
      return (term.isEmpty || p.name.toLowerCase().contains(term)) &&
          (filter.categoryId == null || p.categoryId == filter.categoryId) &&
          p.price >= filter.minPrice &&
          p.price <= filter.maxPrice;
    }).toList();
    final from = filter.page * productsPerPage;
    return ProductPage(
      items: matches.skip(from).take(productsPerPage).toList(),
      totalCount: matches.length,
      page: filter.page,
    );
  }

  @override
  Future<void> addProduct(Product product) async {
    final saved = Product(
      id: _nextId++,
      name: product.name,
      description: product.description,
      price: product.price,
      stock: product.stock,
      imageUrl: product.imageUrl,
      categoryId: product.categoryId,
    );
    products.insert(0, saved);
  }

  @override
  Future<void> updateProduct(Product product) async {
    final index = products.indexWhere((p) => p.id == product.id);
    products[index] = product;
  }

  @override
  Future<void> deleteProduct(int id) async {
    products.removeWhere((p) => p.id == id);
  }
}

// Acts like place_order: checks stock, saves the order, lowers stock.
class FakeOrderService implements OrderService {
  FakeOrderService(this.products, {this.failWith});

  final List<Product> products;
  final Object? failWith;
  final List<Order> orders = [];

  @override
  Future<OrderReceipt> placeOrder(List<CartItem> items) async {
    if (failWith != null) throw failWith!;
    var total = 0.0;
    for (final item in items) {
      final index = products.indexWhere((p) => p.id == item.product.id);
      final product = products[index];
      total += product.price * item.quantity;
      products[index] = product.copyWith(stock: product.stock - item.quantity);
    }
    final order = Order(
      id: orders.length + 1,
      userId: testUser.id,
      status: 'done',
      total: total,
      createdAt: DateTime(2026, 11, 18, 15, 5),
      items: [
        for (final item in items)
          OrderItem(
            id: item.product.id,
            productId: item.product.id,
            productName: item.product.name,
            quantity: item.quantity,
            unitPrice: item.product.price,
          ),
      ],
    );
    orders.insert(0, order);
    return OrderReceipt(orderId: order.id, total: total);
  }

  @override
  Future<List<Order>> fetchMyOrders(String userId) async => orders;

  @override
  Future<List<Order>> fetchAllOrders() async => orders;

  @override
  Future<void> updateStatus(int orderId, String status) async {}
}

final testUser = User(
  id: 'test-user',
  appMetadata: const {'provider': 'email'},
  userMetadata: const {},
  aud: 'authenticated',
  email: 'tester@example.com',
  createdAt: '2026-01-01T00:00:00Z',
);

const adminProfile = Profile(
  id: 'test-user',
  firstName: 'Ada',
  lastName: 'Admin',
  roleName: 'admin',
);

const customerProfile = Profile(
  id: 'test-user',
  firstName: 'Cam',
  lastName: 'Customer',
  roleName: 'customer',
);

// Remembers calls instead of talking to Supabase. signedInAs/signOut push
// auth events, like Supabase does, so providers see the change.
class FakeAuthService implements AuthService {
  FakeAuthService({this.user});

  final _events = StreamController<AuthState>.broadcast();
  User? user;
  final List<String> signInEmails = [];
  final List<String> signUpNames = [];

  @override
  Stream<AuthState> authChanges() => _events.stream;

  @override
  User? get currentUser => user;

  @override
  Future<void> signIn(String email, String password) async {
    signInEmails.add(email);
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    signUpNames.add('$firstName $lastName');
    return true;
  }

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {
    user = null;
    _events.add(const AuthState(AuthChangeEvent.signedOut, null));
  }
}

// profile == null means signed out.
Widget appWith(
  FakeProductService service, {
  Widget? home,
  Profile? profile = adminProfile,
  FakeAuthService? auth,
  FakeOrderService? orders,
}) {
  return ProviderScope(
    overrides: [
      productServiceProvider.overrideWithValue(service),
      orderServiceProvider.overrideWithValue(
        orders ?? FakeOrderService(service.products),
      ),
      categoryProvider.overrideWith((ref) async => categories),
      authServiceProvider.overrideWithValue(auth ?? FakeAuthService()),
      currentUserProvider.overrideWithValue(profile == null ? null : testUser),
      profileProvider.overrideWith((ref) async => profile),
    ],
    child: MaterialApp(home: home ?? const AuthGate()),
  );
}
