import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'home_screen.dart';
import 'product.dart';
import 'product_detail_screen.dart';

void main() {
  runApp(const ShopBrowserApp());
}

class ShopBrowserApp extends StatefulWidget {
  const ShopBrowserApp({super.key});

  @override
  State<ShopBrowserApp> createState() => _ShopBrowserAppState();
}

class _ShopBrowserAppState extends State<ShopBrowserApp> {
  final CartState cart = CartState();
  ThemeMode themeMode = ThemeMode.light;
  late final GoRouter router;

  @override
  void initState() {
    super.initState();
    router = GoRouter(
      initialLocation: '/',
      refreshListenable: cart,
      redirect: (context, state) {
        if (state.matchedLocation == '/checkout' && cart.isEmpty) {
          return '/cart';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => HomeScreen(
            onThemeToggle: () {
              setState(() {
                themeMode = themeMode == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark;
              });
            },
          ),
        ),
        GoRoute(
          path: '/product/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            final product = products.firstWhere((item) => item.id == id);
            return ProductDetailScreen(product: product, cart: cart);
          },
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => CartScreen(cart: cart),
        ),
        GoRoute(
          path: '/checkout',
          builder: (context, state) => CheckoutScreen(cart: cart),
        ),
      ],
    );
  }

  @override
  void dispose() {
    router.dispose();
    cart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Sole Street',
      theme: buildShopTheme(Brightness.light),
      darkTheme: buildShopTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

ThemeData buildShopTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF315C4C),
    brightness: brightness,
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    useMaterial3: true,
    textTheme: TextTheme(
      headlineMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
      bodyLarge: const TextStyle(fontSize: 16),
      bodyMedium: const TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
