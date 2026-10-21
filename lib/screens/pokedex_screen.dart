import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokedex_state.dart';
import '../models/pokemon.dart';
import '../providers/pokedex_notifier.dart';
import '../widgets/favorites_panel.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/type_filter_bar.dart';
import 'pokemon_detail_screen.dart';

class PokedexScreen extends ConsumerWidget {
  const PokedexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch: rebuild this screen whenever the Pokédex state changes.
    final state = ref.watch(pokedexProvider);
    // read: get the notifier once to call a method; no rebuilds needed.
    final notifier = ref.read(pokedexProvider.notifier);
    final hasPokemon =
        state.status == PokemonStatus.success && state.pokemon.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          const FavoritesButton(),
          IconButton(
            onPressed: state.status == PokemonStatus.loading
                ? null
                : notifier.fetchPokemon,
            tooltip: 'Refresh Pokémon',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const FavoritesPanel(),
            if (hasPokemon) const TypeFilterBar(),
            Expanded(
              child: switch (state.status) {
                PokemonStatus.loading => const _LoadingState(),
                PokemonStatus.error => _ErrorState(
                  message: _errorMessage(state.error),
                  onTryAgain: notifier.fetchPokemon,
                ),
                PokemonStatus.success when state.pokemon.isEmpty =>
                  const _EmptyState(),
                PokemonStatus.success when state.visiblePokemon.isEmpty =>
                  _NoMatchState(
                    type: state.selectedType ?? '',
                    onClear: notifier.clearTypeFilter,
                  ),
                PokemonStatus.success => RefreshIndicator(
                  onRefresh: notifier.fetchPokemon,
                  child: _PokemonGrid(pokemon: state.visiblePokemon),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _errorMessage(Object? error) {
    final text = error?.toString() ?? '';
    return text.replaceFirst('Exception: ', '');
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
          // Lets pull-to-refresh work even when the grid is short.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 170 + MediaQuery.textScalerOf(context).scale(80),
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
  const _ErrorState({required this.message, required this.onTryAgain});

  final String message;
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
              Text(
                message.isEmpty
                    ? 'Check your internet connection and try again.'
                    : message,
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

class _NoMatchState extends StatelessWidget {
  const _NoMatchState({required this.type, required this.onClear});

  final String type;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No $type Pokémon found.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onClear,
              child: const Text('Clear filter'),
            ),
          ],
        ),
      ),
    );
  }
}
