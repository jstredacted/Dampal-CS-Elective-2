import 'dart:async';

import 'package:dampal_cs_elective_2/models/pokedex_state.dart';
import 'package:dampal_cs_elective_2/models/pokemon.dart';
import 'package:dampal_cs_elective_2/providers/pokedex_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

ProviderContainer containerWith(FakePokemonService service) {
  return ProviderContainer.test(
    overrides: [pokemonServiceProvider.overrideWithValue(service)],
  );
}

/// Reads the provider (which starts the first fetch) and waits for it.
Future<PokedexState> loaded(ProviderContainer container) async {
  container.read(pokedexProvider);
  await pumpEventQueue();
  return container.read(pokedexProvider);
}

void main() {
  test('starts loading, then succeeds with the service data', () async {
    final service = FakePokemonService(() async => starters);
    final container = containerWith(service);

    expect(container.read(pokedexProvider).status, PokemonStatus.loading);
    final state = await loaded(container);
    expect(state.status, PokemonStatus.success);
    expect(state.pokemon, starters);
    expect(service.calls, 1);
  });

  test('stores the error when the fetch fails', () async {
    final container = containerWith(
      FakePokemonService(() => Future.error(Exception('Offline'))),
    );
    final state = await loaded(container);
    expect(state.status, PokemonStatus.error);
    expect(state.error.toString(), contains('Offline'));
  });

  test('fetchPokemon ignores a second call while one is running', () async {
    final pending = Completer<List<Pokemon>>();
    final service = FakePokemonService(() => pending.future);
    final container = containerWith(service);
    container.read(pokedexProvider);
    await pumpEventQueue();

    unawaited(container.read(pokedexProvider.notifier).fetchPokemon());
    expect(service.calls, 1);
    pending.complete(starters);
    await pumpEventQueue();
    expect(container.read(pokedexProvider).status, PokemonStatus.success);
  });

  test('refresh keeps nicknames, favorites, and the type filter', () async {
    final service = FakePokemonService(() async => starters);
    final container = containerWith(service);
    await loaded(container);
    final notifier = container.read(pokedexProvider.notifier);

    notifier.setNickname(4, 'Blaze');
    notifier.toggleFavorite(7);
    notifier.selectType('fire');
    await notifier.fetchPokemon();

    final state = container.read(pokedexProvider);
    expect(service.calls, 2);
    expect(state.nicknameFor(4), 'Blaze');
    expect(state.isFavorite(7), isTrue);
    expect(state.selectedType, 'fire');
  });

  test('nicknames are trimmed, edited, and removed', () async {
    final container = containerWith(FakePokemonService(() async => starters));
    await loaded(container);
    final notifier = container.read(pokedexProvider.notifier);

    notifier.setNickname(1, '  Bulby ');
    expect(container.read(pokedexProvider).nicknameFor(1), 'Bulby');
    notifier.setNickname(1, 'Leafy');
    expect(container.read(pokedexProvider).nicknameFor(1), 'Leafy');
    notifier.removeNickname(1);
    expect(container.read(pokedexProvider).nicknameFor(1), isNull);
    notifier.setNickname(1, 'Leafy');
    notifier.setNickname(1, '   ');
    expect(container.read(pokedexProvider).nicknameFor(1), isNull);
  });

  test('toggleFavorite adds then removes, and favorites follow', () async {
    final container = containerWith(FakePokemonService(() async => starters));
    await loaded(container);
    final notifier = container.read(pokedexProvider.notifier);

    notifier.toggleFavorite(4);
    expect(container.read(pokedexProvider).favorites, [charmander]);
    notifier.toggleFavorite(4);
    expect(container.read(pokedexProvider).favorites, isEmpty);
  });

  test('type filter uses real type data and can be cleared', () async {
    final container = containerWith(FakePokemonService(() async => starters));
    final state = await loaded(container);
    final notifier = container.read(pokedexProvider.notifier);

    expect(state.availableTypes, ['fire', 'grass', 'poison', 'water']);
    notifier.selectType('poison');
    expect(container.read(pokedexProvider).visiblePokemon, [bulbasaur]);
    notifier.clearTypeFilter();
    expect(container.read(pokedexProvider).selectedType, isNull);
    expect(container.read(pokedexProvider).visiblePokemon, starters);
  });

  test('favorites panel flag toggles', () async {
    final container = containerWith(FakePokemonService(() async => starters));
    await loaded(container);
    final notifier = container.read(pokedexProvider.notifier);

    expect(container.read(pokedexProvider).isFavoritesOpen, isFalse);
    notifier.toggleFavoritesPanel();
    expect(container.read(pokedexProvider).isFavoritesOpen, isTrue);
  });

  test('disposing while loading does not throw', () async {
    final pending = Completer<List<Pokemon>>();
    final container = ProviderContainer(
      overrides: [
        pokemonServiceProvider.overrideWithValue(
          FakePokemonService(() => pending.future),
        ),
      ],
    );
    container.read(pokedexProvider);
    await pumpEventQueue();
    container.dispose();
    pending.complete(starters);
    await pumpEventQueue();
  });
}
