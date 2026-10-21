import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/pokedex_notifier.dart';
import 'type_label.dart';

class PokemonCard extends ConsumerWidget {
  const PokemonCard({required this.pokemon, this.onTap, super.key});

  final Pokemon pokemon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select() rebuilds this card only when its own nickname or favorite
    // status changes, not when another Pokémon changes.
    final nickname = ref.watch(
      pokedexProvider.select((state) => state.nicknameFor(pokemon.id)),
    );
    final isFavorite = ref.watch(
      pokedexProvider.select((state) => state.isFavorite(pokemon.id)),
    );
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.network(
                        pokemon.imageUrl,
                        fit: BoxFit.contain,
                        semanticLabel: '${pokemon.name} image',
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return const CircularProgressIndicator.adaptive();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '#${pokemon.id.toString().padLeft(3, '0')}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nickname ?? pokemon.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // The original name stays visible under a nickname.
                  if (nickname != null)
                    Text(
                      pokemon.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final type in pokemon.types) TypeLabel(type: type),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => ref
                    .read(pokedexProvider.notifier)
                    .toggleFavorite(pokemon.id),
                tooltip: isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
