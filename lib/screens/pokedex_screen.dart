import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pokemon.dart';
import '../providers/pokemon_provider.dart';
import '../widgets/pokemon_card.dart';
import 'pokemon_detail_screen.dart';

class PokedexScreen extends StatelessWidget {
  const PokedexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pokemonProvider = context.watch<PokemonProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: pokemonProvider.status == PokemonStatus.loading
                ? null
                : () => context.read<PokemonProvider>().fetchPokemon(),
            tooltip: 'Refresh Pokémon',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (pokemonProvider.status) {
          PokemonStatus.loading => const _LoadingState(),
          PokemonStatus.error => _ErrorState(
            onTryAgain: () => context.read<PokemonProvider>().fetchPokemon(),
          ),
          PokemonStatus.success when pokemonProvider.pokemon.isEmpty =>
            const _EmptyState(),
          PokemonStatus.success => _PokemonGrid(
            pokemon: pokemonProvider.pokemon,
          ),
        },
      ),
    );
  }
}

class _PokemonGrid extends StatelessWidget {
  const _PokemonGrid({required this.pokemon});

  final List<Pokemon> pokemon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (constraints.maxWidth) {
          < 600 => 2,
          < 840 => 3,
          < 1200 => 4,
          _ => 5,
        };

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 170 + MediaQuery.textScalerOf(context).scale(40),
          ),
          itemCount: pokemon.length,
          itemBuilder: (context, index) {
            final selectedPokemon = pokemon[index];
            return PokemonCard(
              pokemon: selectedPokemon,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PokemonDetailScreen(pokemonId: selectedPokemon.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator.adaptive(),
          SizedBox(height: 16),
          Text('Loading Pokémon…'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onTryAgain});

  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load Pokémon.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your internet connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onTryAgain,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No Pokémon found.', textAlign: TextAlign.center),
      ),
    );
  }
}
