import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/pokedex_screen.dart';
import 'providers/pokemon_provider.dart';
import 'services/pokemon_service.dart';

void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({this.service, super.key});

  final PokemonService? service;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              PokemonProvider(service: service ?? PokemonService())
                ..fetchPokemon(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Pokédex',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFDC0A2D),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const PokedexScreen(),
      ),
    );
  }
}
