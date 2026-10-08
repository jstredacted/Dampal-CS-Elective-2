import 'package:flutter/material.dart';

import '../models/pokemon.dart';

class PokemonCard extends StatelessWidget {
  const PokemonCard({required this.pokemon, this.onTap, super.key});

  final Pokemon pokemon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
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
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                pokemon.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
