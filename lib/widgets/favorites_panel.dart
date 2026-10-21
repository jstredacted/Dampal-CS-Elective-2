import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pokedex_notifier.dart';
import '../screens/pokemon_detail_screen.dart';

/// AppBar action that opens and closes the favorites panel.
class FavoritesButton extends ConsumerWidget {
  const FavoritesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      pokedexProvider.select((state) => state.favoriteIds.length),
    );
    final isOpen = ref.watch(
      pokedexProvider.select((state) => state.isFavoritesOpen),
    );

    return IconButton(
      onPressed: () =>
          ref.read(pokedexProvider.notifier).toggleFavoritesPanel(),
      tooltip: isOpen ? 'Hide favorites' : 'Show favorites',
      icon: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        child: Icon(isOpen ? Icons.favorite : Icons.favorite_border),
      ),
    );
  }
}

/// Retractable panel under the AppBar. It is placed on every screen and its
/// open/closed flag lives in Riverpod, so it looks the same everywhere.
class FavoritesPanel extends ConsumerWidget {
  const FavoritesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pokedexProvider);
    final favorites = state.favorites;
    final theme = Theme.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: !state.isFavoritesOpen
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              color: theme.colorScheme.primaryContainer,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Favorites (${favorites.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (favorites.isEmpty)
                    Text(
                      'No favorite Pokémon yet. Tap a heart to add one.',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                  else
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: favorites.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final pokemon = favorites[index];
                          return InputChip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: NetworkImage(pokemon.imageUrl),
                              // A missing sprite just leaves the circle blank.
                              onBackgroundImageError: (_, _) {},
                            ),
                            label: Text(
                              state.nicknameFor(pokemon.id) ?? pokemon.name,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PokemonDetailScreen(pokemonId: pokemon.id),
                              ),
                            ),
                            onDeleted: () => ref
                                .read(pokedexProvider.notifier)
                                .toggleFavorite(pokemon.id),
                            deleteButtonTooltipMessage: 'Remove from favorites',
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
