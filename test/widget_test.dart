import 'package:dampal_cs_elective_2/main.dart';
import 'package:dampal_cs_elective_2/product.dart';
import 'package:dampal_cs_elective_2/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines shared text styles for both themes', () {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final theme = buildShopTheme(brightness);

      expect(theme.brightness, brightness);
      expect(theme.textTheme.headlineMedium?.fontSize, 28);
      expect(theme.textTheme.headlineSmall?.fontWeight, FontWeight.bold);
      expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.bold);
      expect(theme.textTheme.titleMedium?.fontWeight, FontWeight.w600);
      expect(theme.textTheme.titleSmall?.color, theme.colorScheme.primary);
      expect(theme.textTheme.bodyLarge?.fontSize, 16);
      expect(theme.textTheme.bodyMedium?.fontSize, 14);
      expect(
        theme.textTheme.bodySmall?.color,
        theme.colorScheme.onSurfaceVariant,
      );
      expect(theme.textTheme.labelLarge?.fontWeight, FontWeight.bold);
      expect(
        theme.appBarTheme.titleTextStyle?.color,
        theme.colorScheme.onSurface,
      );
    }
  });

  testWidgets('toggles dark mode on and off', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShopBrowserApp());

    MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme-toggle')));
    await tester.pumpAndSettle();

    app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme-toggle')));
    await tester.pumpAndSettle();

    app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });

  testWidgets('uses responsive product grid columns', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShopBrowserApp());

    GridView grid = tester.widget(find.byType(GridView));
    var delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(900, 1000);
    await tester.pumpAndSettle();

    grid = tester.widget(find.byType(GridView));
    delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1300, 1000);
    await tester.pumpAndSettle();

    grid = tester.widget(find.byType(GridView));
    delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows when a product is already in the cart', (tester) async {
    final cart = CartState();
    cart.add(products.first);
    addTearDown(cart.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(product: products.first, cart: cart),
      ),
    );

    expect(find.text('Added to Cart'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const ValueKey('add-to-cart-button')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('updates the product button after cart removal', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShopBrowserApp());

    await tester.tap(find.byKey(const ValueKey('product-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-to-cart-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('detail-cart-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('decrease-1')));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Add to Cart'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const ValueKey('add-to-cart-button')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('opens a product and completes checkout', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShopBrowserApp());

    expect(find.text('Sole Street'), findsOneWidget);
    expect(find.text('Crimson Runner'), findsOneWidget);
    expect(find.text('Step into something new'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('product-1')));
    await tester.pumpAndSettle();

    expect(find.text('Product Detail'), findsOneWidget);
    expect(find.text('₱2499'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('add-to-cart-button')));
    await tester.pumpAndSettle();

    expect(find.text('Added to Cart'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('detail-cart-button')));
    await tester.pumpAndSettle();

    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Subtotal: ₱2499'), findsOneWidget);
    expect(find.text('Total: ₱2499'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('increase-1')));
    await tester.pumpAndSettle();

    expect(find.text('Subtotal: ₱4998'), findsOneWidget);
    expect(find.text('Total: ₱4998'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('checkout-button')));
    await tester.pumpAndSettle();

    expect(find.text('Checkout Confirmation'), findsOneWidget);
    expect(find.text('Order Confirmed!'), findsOneWidget);
    expect(find.text('Total: ₱4998'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
