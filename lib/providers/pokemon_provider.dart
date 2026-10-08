import 'package:flutter/foundation.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';

enum PokemonStatus { loading, success, error }

class PokemonProvider extends ChangeNotifier {
  PokemonProvider({required this.service});

  final PokemonService service;

  PokemonStatus _status = PokemonStatus.loading;
  List<Pokemon> _pokemon = const [];
  Object? _error;
  bool _isFetching = false;
  bool _disposed = false;

  PokemonStatus get status => _status;
  List<Pokemon> get pokemon => List.unmodifiable(_pokemon);
  Object? get error => _error;

  Future<void> fetchPokemon() async {
    if (_isFetching || _disposed) return;
    _isFetching = true;
    _status = PokemonStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final pokemon = await service.fetchPokemon();
      if (_disposed) return;
      _pokemon = pokemon;
      _status = PokemonStatus.success;
    } catch (error) {
      if (_disposed) return;
      _error = error;
      _status = PokemonStatus.error;
    } finally {
      _isFetching = false;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
