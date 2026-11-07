import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/products_page.dart';

Future<void> main() async {
  // Supabase.initialize runs before runApp, so Flutter must be ready first.
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://midiimufzoiitaajxolw.supabase.co',
    publishableKey: 'sb_publishable_xvaY61f-NaPc4a3-YlSwXQ_e458xmh-',
  );

  runApp(
    // ProviderScope stores the state of every Riverpod provider in the app.
    const ProviderScope(child: SoleStreetApp()),
  );
}

class SoleStreetApp extends StatelessWidget {
  const SoleStreetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF315C4C),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sole Street',
      // On web and desktop, Flutter only drags lists with touch by default.
      // Allowing every pointer lets a mouse or trackpad scroll by dragging too.
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: colorScheme.surfaceContainerLow,
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const ProductsPage(),
    );
  }
}
