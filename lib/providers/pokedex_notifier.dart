import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokedex_state.dart';
import '../services/pokemon_service.dart';

/// Tests replace this with a fake service through `overrideWithValue`.
final pokemonServiceProvider = Provider<PokemonService>(
  (ref) => PokemonService(),
);

final pokedexProvider = NotifierProvider<PokedexNotifier, PokedexState>(
  PokedexNotifier.new,
);

class PokedexNotifier extends Notifier<PokedexState> {
  bool _isFetching = false;

  @override
  PokedexState build() {
    // State cannot change while build() is still running, so the first fetch
    // waits for the microtask queue.
    Future.microtask(fetchPokemon);
    return const PokedexState();
  }

  /// Used for the first load, the refresh button, pull-to-refresh, and retry.
  Future<void> fetchPokemon() async {
    if (_isFetching || !ref.mounted) return;
    _isFetching = true;
    state = state.copyWith(status: PokemonStatus.loading, clearError: true);

    try {
      final pokemon = await ref.read(pokemonServiceProvider).fetchPokemon();
      if (!ref.mounted) return;
      state = state.copyWith(status: PokemonStatus.success, pokemon: pokemon);
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(status: PokemonStatus.error, error: error);
    } finally {
      _isFetching = false;
    }
  }

  void setNickname(int id, String nickname) {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) {
      removeNickname(id);
      return;
    }
    state = state.copyWith(nicknames: {...state.nicknames, id: trimmed});
  }

  void removeNickname(int id) {
    final nicknames = {...state.nicknames}..remove(id);
    state = state.copyWith(nicknames: nicknames);
  }

  void toggleFavorite(int id) {
    final favorites = {...state.favoriteIds};
    if (!favorites.remove(id)) {
      favorites.add(id);
    }
    state = state.copyWith(favoriteIds: favorites);
  }

  void selectType(String type) {
    state = state.copyWith(selectedType: type);
  }

  void clearTypeFilter() {
    state = state.copyWith(clearSelectedType: true);
  }

  void toggleFavoritesPanel() {
    state = state.copyWith(isFavoritesOpen: !state.isFavoritesOpen);
  }
}
