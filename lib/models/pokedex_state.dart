import 'pokemon.dart';

enum PokemonStatus { loading, success, error }

/// Everything the Pokédex screens share. It is never changed in place;
/// the notifier replaces it with a new copy so Riverpod can notify widgets.
class PokedexState {
  const PokedexState({
    this.status = PokemonStatus.loading,
    this.pokemon = const [],
    this.error,
    this.nicknames = const {},
    this.favoriteIds = const {},
    this.selectedType,
    this.isFavoritesOpen = false,
  });

  final PokemonStatus status;
  final List<Pokemon> pokemon;
  final Object? error;
  final Map<int, String> nicknames;
  final Set<int> favoriteIds;
  final String? selectedType;
  final bool isFavoritesOpen;

  /// `selectedType: null` cannot mean "remove the filter" because null also
  /// means "keep the old value", so clearing uses its own flag.
  PokedexState copyWith({
    PokemonStatus? status,
    List<Pokemon>? pokemon,
    Object? error,
    bool clearError = false,
    Map<int, String>? nicknames,
    Set<int>? favoriteIds,
    String? selectedType,
    bool clearSelectedType = false,
    bool? isFavoritesOpen,
  }) {
    return PokedexState(
      status: status ?? this.status,
      pokemon: pokemon ?? this.pokemon,
      error: clearError ? null : (error ?? this.error),
      nicknames: nicknames ?? this.nicknames,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      selectedType: clearSelectedType
          ? null
          : (selectedType ?? this.selectedType),
      isFavoritesOpen: isFavoritesOpen ?? this.isFavoritesOpen,
    );
  }

  /// The list the home grid shows, after the type filter.
  List<Pokemon> get visiblePokemon {
    final type = selectedType;
    if (type == null) return pokemon;
    return pokemon.where((p) => p.types.contains(type)).toList();
  }

  List<Pokemon> get favorites =>
      pokemon.where((p) => favoriteIds.contains(p.id)).toList();

  /// Every type found in the loaded Pokémon, in alphabetical order.
  List<String> get availableTypes {
    final types = <String>{for (final p in pokemon) ...p.types};
    return types.toList()..sort();
  }

  bool isFavorite(int id) => favoriteIds.contains(id);

  String? nicknameFor(int id) => nicknames[id];
}
