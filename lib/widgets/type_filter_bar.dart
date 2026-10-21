import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pokedex_notifier.dart';
import 'type_label.dart';

/// A row of chips built from the types found in the loaded Pokémon.
/// "All" clears the filter.
class TypeFilterBar extends ConsumerWidget {
  const TypeFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pokedexProvider);
    final selectedType = state.selectedType;
    final notifier = ref.read(pokedexProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selectedType == null,
            onSelected: (_) => notifier.clearTypeFilter(),
          ),
          for (final type in state.availableTypes)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(type),
                avatar: CircleAvatar(backgroundColor: typeColor(type)),
                selected: selectedType == type,
                onSelected: (selected) => selected
                    ? notifier.selectType(type)
                    : notifier.clearTypeFilter(),
              ),
            ),
        ],
      ),
    );
  }
}
