import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/pokedex_screen.dart';

void main() {
  runApp(
    // ProviderScope stores the state of every Riverpod provider in the app.
    const ProviderScope(child: PokedexApp()),
  );
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex',
      // On web and desktop, Flutter only drags lists with touch by default.
      // Allowing every pointer lets a mouse or trackpad pull to refresh too.
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFDC0A2D),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const PokedexScreen(),
    );
  }
}
