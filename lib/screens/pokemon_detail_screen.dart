import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pokedex_notifier.dart';
import '../widgets/favorites_panel.dart';
import '../widgets/nickname_dialog.dart';
import '../widgets/type_label.dart';

class PokemonDetailScreen extends ConsumerWidget {
  const PokemonDetailScreen({required this.pokemonId, super.key});

  final int pokemonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pokedexProvider);
    final matches = state.pokemon.where((pokemon) => pokemon.id == pokemonId);

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pokémon')),
        body: const Center(child: Text('Pokémon not found.')),
      );
    }

    final pokemon = matches.first;
    final nickname = state.nicknameFor(pokemon.id);
    final isFavorite = state.isFavorite(pokemon.id);
    final notifier = ref.read(pokedexProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(nickname ?? pokemon.name),
        actions: const [FavoritesButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const FavoritesPanel(),
            Expanded(
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
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.image_not_supported_outlined,
                                size: 80,
                              ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          nickname ?? pokemon.name,
                          style: theme.textTheme.headlineMedium,
                        ),
                        if (nickname != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Original name: ${pokemon.name}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '#${pokemon.id.toString().padLeft(3, '0')}',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final type in pokemon.types)
                              TypeLabel(type: type),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () =>
                                  notifier.toggleFavorite(pokemon.id),
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                              ),
                              label: Text(
                                isFavorite
                                    ? 'Remove from favorites'
                                    : 'Add to favorites',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) =>
                                    NicknameDialog(pokemon: pokemon),
                              ),
                              icon: const Icon(Icons.edit),
                              label: Text(
                                nickname == null
                                    ? 'Add nickname'
                                    : 'Edit nickname',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
