import 'package:dampal_cs_elective_2/models/category.dart';
import 'package:dampal_cs_elective_2/models/product.dart';
import 'package:dampal_cs_elective_2/models/product_filter.dart';
import 'package:dampal_cs_elective_2/models/product_page.dart';
import 'package:dampal_cs_elective_2/pages/products_page.dart';
import 'package:dampal_cs_elective_2/providers/category_provider.dart';
import 'package:dampal_cs_elective_2/providers/product_provider.dart';
import 'package:dampal_cs_elective_2/providers/user_provider.dart';
import 'package:dampal_cs_elective_2/services/auth_service.dart';
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

final testUser = User(
  id: 'test-user',
  appMetadata: const {'provider': 'email'},
  userMetadata: const {},
  aud: 'authenticated',
  email: 'tester@example.com',
  createdAt: '2026-01-01T00:00:00Z',
);

// Remembers sign-in calls instead of talking to Supabase.
class FakeAuthService implements AuthService {
  final List<String> signInEmails = [];

  @override
  Stream<AuthState> authChanges() => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<void> signIn(String email, String password) async {
    signInEmails.add(email);
  }

  @override
  Future<bool> signUp(String email, String password) async => true;

  @override
  Future<void> signInWithGitHub() async {}

  @override
  Future<void> signOut() async {}
}

Widget appWith(
  FakeProductService service, {
  Widget? home,
  bool signedIn = true,
  FakeAuthService? auth,
}) {
  return ProviderScope(
    overrides: [
      productServiceProvider.overrideWithValue(service),
      categoryProvider.overrideWith((ref) async => categories),
      authServiceProvider.overrideWithValue(auth ?? FakeAuthService()),
      currentUserProvider.overrideWithValue(signedIn ? testUser : null),
    ],
    child: MaterialApp(home: home ?? const ProductsPage()),
  );
}
