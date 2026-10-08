import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pokemon_provider.dart';

class PokemonDetailScreen extends StatelessWidget {
  const PokemonDetailScreen({required this.pokemonId, super.key});

  final int pokemonId;

  @override
  Widget build(BuildContext context) {
    final pokemonProvider = context.watch<PokemonProvider>();
    final matches = pokemonProvider.pokemon.where(
      (pokemon) => pokemon.id == pokemonId,
    );

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pokémon')),
        body: const Center(child: Text('Pokémon not found.')),
      );
    }

    final pokemon = matches.first;

    return Scaffold(
      appBar: AppBar(title: Text(pokemon.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    pokemon.imageUrl,
                    height: 220,
                    width: 220,
                    fit: BoxFit.contain,
                    semanticLabel: '${pokemon.name} image',
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported_outlined,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    pokemon.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '#${pokemon.id.toString().padLeft(3, '0')}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
