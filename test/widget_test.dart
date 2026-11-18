import 'package:dampal_cs_elective_2/models/product.dart';
import 'package:dampal_cs_elective_2/models/product_page.dart';
import 'package:dampal_cs_elective_2/pages/product_form_page.dart';
import 'package:dampal_cs_elective_2/providers/cart_provider.dart';
import 'package:dampal_cs_elective_2/providers/product_filter_provider.dart';
import 'package:dampal_cs_elective_2/providers/product_provider.dart';
import 'package:dampal_cs_elective_2/providers/user_provider.dart';
import 'package:dampal_cs_elective_2/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';

Future<void> useTallScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

String fieldText(WidgetTester tester, String label) {
  final field = tester.widget<TextField>(
    find.descendant(
      of: find.widgetWithText(TextFormField, label),
      matching: find.byType(TextField),
    ),
  );
  return field.controller!.text;
}

void main() {
  test('totalPages rounds up and is at least 1', () {
    expect(const ProductPage(items: [], totalCount: 21, page: 0).totalPages, 4);
    expect(const ProductPage(items: [], totalCount: 12, page: 0).totalPages, 2);
    expect(const ProductPage(items: [], totalCount: 0, page: 0).totalPages, 1);
  });

  test('formatPeso adds commas and two decimals', () {
    expect(formatPeso(12999), '₱12,999.00');
    expect(formatPeso(500.5), '₱500.50');
    expect(formatPeso(1234567), '₱1,234,567.00');
  });

  test('formatDateTime shows a 12-hour time', () {
    expect(
      formatDateTime(DateTime(2026, 11, 18, 15, 5)),
      'Nov 18, 2026 · 3:05 PM',
    );
    expect(
      formatDateTime(DateTime(2026, 1, 2, 0, 30)),
      'Jan 2, 2026 · 12:30 AM',
    );
  });

  test('changing the price range goes back to the first page', () async {
    final service = FakeProductService(sampleProducts());
    final container = ProviderContainer(
      overrides: [productServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final filter = container.read(productFilterProvider.notifier);

    filter.setPage(2);
    filter.setPriceRange(2000, 6000);
    final page = await container.read(productProvider.future);

    expect(service.requests.last.page, 0);
    expect(service.requests.last.minPrice, 2000);
    // Shoes 4-12 cost ₱2,000-₱6,000, so page 1 shows Shoes 4-9.
    expect(page.totalCount, 9);
    expect(page.items.map((p) => p.name), [
      'Shoe 4',
      'Shoe 5',
      'Shoe 6',
      'Shoe 7',
      'Shoe 8',
      'Shoe 9',
    ]);
  });

  group('cart', () {
    late FakeAuthService auth;
    late ProviderContainer container;

    setUp(() {
      auth = FakeAuthService(user: testUser);
      container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(auth)],
      );
      // Keeps the cart alive for the whole test.
      container.listen(cartProvider, (_, _) {});
    });
    tearDown(() => container.dispose());

    test('limits quantities to the stock and totals the items', () {
      final cart = container.read(cartProvider.notifier);
      final shoe2 = sampleProducts()[1]; // 2 in stock, ₱1,000

      expect(cart.add(shoe2), isNull);
      expect(cart.add(shoe2), isNull);
      expect(cart.add(shoe2), 'Only 2 of Shoe 2 available.');
      expect(cart.setQuantity(shoe2.id, 5), 'Only 2 of Shoe 2 available.');
      expect(container.read(cartCountProvider), 2);
      expect(container.read(cartTotalProvider), 2000);

      cart.setQuantity(shoe2.id, 0);
      expect(container.read(cartProvider), isEmpty);
    });

    test('refuses out-of-stock products', () {
      final soldOut = sampleProducts().first.copyWith(stock: 0);
      final error = container.read(cartProvider.notifier).add(soldOut);
      expect(error, 'Shoe 1 is out of stock.');
      expect(container.read(cartProvider), isEmpty);
    });

    test('is emptied on logout', () async {
      container.read(cartProvider.notifier).add(sampleProducts()[4]);
      expect(container.read(cartCountProvider), 1);

      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(currentUserProvider), isNull);
      expect(container.read(cartProvider), isEmpty);
    });
  });

  testWidgets('signed-out users only see the login page', (tester) async {
    await useTallScreen(tester);
    await tester.pumpWidget(
      appWith(FakeProductService(sampleProducts()), profile: null),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(find.text('Shoe 1'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('shows 6 products per page and moves between pages', (
    tester,
  ) async {
    await useTallScreen(tester);
    await tester.pumpWidget(appWith(FakeProductService(sampleProducts())));
    await tester.pumpAndSettle();

    expect(find.text('Page 1 of 4'), findsOneWidget);
    expect(find.text('21 products'), findsOneWidget);
    expect(find.text('Shoe 6'), findsOneWidget);
    expect(find.text('Shoe 7'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Page 2 of 4'), findsOneWidget);
    expect(find.text('Shoe 7'), findsOneWidget);
    expect(find.text('Shoe 1'), findsNothing);

    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Page 1 of 4'), findsOneWidget);
  });

  testWidgets('category and search filters reset to page 1', (tester) async {
    await useTallScreen(tester);
    await tester.pumpWidget(appWith(FakeProductService(sampleProducts())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Skate'));
    await tester.pumpAndSettle();
    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(find.text('10 products'), findsOneWidget);
    expect(find.text('Shoe 2'), findsOneWidget);
    expect(find.text('Shoe 1'), findsNothing);

    await tester.enterText(find.byType(TextField), 'shoe 1');
    await tester.pumpAndSettle();
    // Skate shoes whose names contain "shoe 1": 10, 12, 14, 16, 18.
    expect(find.text('5 products'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('21 products'), findsOneWidget);
    expect(find.text('shoe 1'), findsNothing);
  });

  testWidgets('add form opens empty and shows validation errors', (
    tester,
  ) async {
    await useTallScreen(tester);
    await tester.pumpWidget(
      appWith(
        FakeProductService(sampleProducts()),
        home: const ProductFormPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add product'), findsWidgets);
    expect(fieldText(tester, 'Name'), isEmpty);
    expect(fieldText(tester, 'Price (₱)'), isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Add product'));
    await tester.pumpAndSettle();
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Price is required'), findsOneWidget);
    expect(find.text('Choose a category'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price (₱)'),
      '-1',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Stock'), '1.5');
    await tester.tap(find.widgetWithText(FilledButton, 'Add product'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a price of 0 or more'), findsOneWidget);
    expect(find.text('Enter a whole number, 0 or more'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price (₱)'),
      '0',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add product'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a price of 0 or more'), findsNothing);
  });

  testWidgets('admin adds a product from the shop and sees it on page 1', (
    tester,
  ) async {
    await useTallScreen(tester);
    final service = FakeProductService(sampleProducts());
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Neo');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price (₱)'),
      '4500',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Stock'), '3');
    await tester.tap(find.text('Choose a category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Running').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add product'));
    await tester.pumpAndSettle();

    expect(find.text('Added Neo'), findsOneWidget);
    expect(find.text('Page 1 of 4'), findsOneWidget);
    expect(find.text('22 products'), findsOneWidget);
    expect(find.text('Neo'), findsOneWidget);
  });

  testWidgets('edit form opens prefilled and saves changes', (tester) async {
    await useTallScreen(tester);
    final service = FakeProductService(sampleProducts());
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit Shoe 3'));
    await tester.pumpAndSettle();
    expect(find.text('Edit product'), findsOneWidget);
    expect(fieldText(tester, 'Name'), 'Shoe 3');
    expect(fieldText(tester, 'Price (₱)'), '1500.00');
    expect(fieldText(tester, 'Stock'), '3');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Shoe 3 Pro',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Updated Shoe 3 Pro'), findsOneWidget);
    expect(find.text('Shoe 3 Pro'), findsWidgets);
    final saved = service.products.firstWhere((p) => p.id == 3);
    expect(saved.name, 'Shoe 3 Pro');
    expect(saved.price, 1500);
  });

  testWidgets('admins see management controls and no cart', (tester) async {
    await useTallScreen(tester);
    await tester.pumpWidget(appWith(FakeProductService(sampleProducts())));
    await tester.pumpAndSettle();

    expect(find.text('Sole Street · Admin'), findsOneWidget);
    expect(find.byTooltip('Account'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Edit Shoe 1'), findsOneWidget);
    expect(find.byTooltip('Delete Shoe 1'), findsOneWidget);
    expect(find.byTooltip('Categories'), findsOneWidget);
    expect(find.byTooltip('All orders'), findsOneWidget);
    expect(find.byTooltip('Cart'), findsNothing);
    expect(find.text('Add to cart'), findsNothing);
  });

  testWidgets('customers see add to cart instead of admin controls', (
    tester,
  ) async {
    await useTallScreen(tester);
    await tester.pumpWidget(
      appWith(FakeProductService(sampleProducts()), profile: customerProfile),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sole Street'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('Edit Shoe 1'), findsNothing);
    expect(find.byTooltip('Delete Shoe 1'), findsNothing);
    expect(find.byTooltip('Categories'), findsNothing);
    expect(find.byTooltip('Cart'), findsOneWidget);
    expect(find.byTooltip('My orders'), findsOneWidget);
    expect(find.text('Add to cart'), findsNWidgets(6));
  });

  testWidgets('add to cart stops at the stock and blocks sold-out shoes', (
    tester,
  ) async {
    await useTallScreen(tester);
    final products = sampleProducts();
    products[1] = products[1].copyWith(stock: 0); // Shoe 2 sold out
    await tester.pumpWidget(
      appWith(FakeProductService(products), profile: customerProfile),
    );
    await tester.pumpAndSettle();

    expect(find.text('Out of stock'), findsWidgets);
    // Shoe 1 has 1 pair, so one tap fills the cart for it.
    await tester.tap(find.text('Add to cart').first);
    await tester.pumpAndSettle();
    expect(find.text('Added Shoe 1 to your cart'), findsOneWidget);
    expect(find.text('All 1 in cart'), findsOneWidget);
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('All 1 in cart'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('checkout shows the order number, total, and empties the cart', (
    tester,
  ) async {
    await useTallScreen(tester);
    final service = FakeProductService(sampleProducts());
    final orders = FakeOrderService(service.products);
    await tester.pumpWidget(
      appWith(service, profile: customerProfile, orders: orders),
    );
    await tester.pumpAndSettle();

    // Shoe 4 (₱2,000) twice.
    await tester.tap(find.text('Add to cart').at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add (1 in cart)'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('Total ₱4,000.00'), findsOneWidget);

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    expect(find.text('Order #1'), findsOneWidget);
    expect(find.text('Total paid ₱4,000.00'), findsOneWidget);
    expect(service.products.firstWhere((p) => p.id == 4).stock, 2);

    await tester.tap(find.text('View my orders'));
    await tester.pumpAndSettle();
    expect(find.text('My orders'), findsOneWidget);
    expect(find.text('2 × Shoe 4'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Add (1 in cart)'), findsNothing);
  });

  testWidgets('a failed checkout keeps the cart and shows why', (tester) async {
    await useTallScreen(tester);
    final service = FakeProductService(sampleProducts());
    final orders = FakeOrderService(
      service.products,
      failWith: const PostgrestException(
        message: 'Only 1 left of Shoe 4.',
        code: '23514',
      ),
    );
    await tester.pumpWidget(
      appWith(service, profile: customerProfile, orders: orders),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to cart').at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    expect(
      find.text('Checkout failed: Only 1 left of Shoe 4.'),
      findsOneWidget,
    );
    expect(find.text('Shoe 4'), findsOneWidget);
    expect(orders.orders, isEmpty);
  });

  testWidgets('login page checks the form before signing in', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(
      appWith(FakeProductService(sampleProducts()), profile: null, auth: auth),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(auth.signInEmails, isEmpty);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'tester@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      '123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Use at least 6 characters'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(auth.signInEmails, ['tester@example.com']);
  });

  testWidgets('sign-up page asks for names and matching passwords', (
    tester,
  ) async {
    await useTallScreen(tester);
    final auth = FakeAuthService();
    await tester.pumpWidget(
      appWith(FakeProductService(sampleProducts()), profile: null, auth: auth),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('No account yet? Create one'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Last name is required'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      'Cam',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last name'),
      'Lee',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'cam@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'secret12',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(auth.signUpNames, ['Cam Lee']);
  });

  testWidgets('deleting the only product on the last page goes back a page', (
    tester,
  ) async {
    await useTallScreen(tester);
    // 19 products → pages of 6, 6, 6, and 1 (only Shoe 19 on page 4).
    final service = FakeProductService(sampleProducts().take(19).toList());
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Page 4 of 4'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete Shoe 19'));
    await tester.pumpAndSettle();
    expect(
      find.text('Delete "Shoe 19"? This cannot be undone.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Shoe 19'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete Shoe 19'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Deleted Shoe 19'), findsOneWidget);
    expect(find.text('Page 3 of 3'), findsOneWidget);
    expect(find.text('18 products'), findsOneWidget);
    expect(service.products.any((Product p) => p.id == 19), isFalse);
  });
}
