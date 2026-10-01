import 'package:flutter/material.dart';

import 'screens/pokedex_screen.dart';
import 'services/pokemon_service.dart';

void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({this.service, super.key});

  final PokemonService? service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFDC0A2D),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: PokedexScreen(service: service),
    );
  }
}
