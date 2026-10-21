import 'package:dampal_cs_elective_2/main.dart';
import 'package:dampal_cs_elective_2/models/pokemon.dart';
import 'package:dampal_cs_elective_2/providers/pokedex_notifier.dart';
import 'package:dampal_cs_elective_2/services/pokemon_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FakePokemonService extends PokemonService {
  FakePokemonService(this.load);

  final Future<List<Pokemon>> Function() load;
  int calls = 0;

  @override
  Future<List<Pokemon>> fetchPokemon() {
    calls++;
    return load();
  }
}

const bulbasaur = Pokemon(
  name: 'bulbasaur',
  id: 1,
  imageUrl: '',
  types: ['grass', 'poison'],
);
const charmander = Pokemon(
  name: 'charmander',
  id: 4,
  imageUrl: '',
  types: ['fire'],
);
const squirtle = Pokemon(
  name: 'squirtle',
  id: 7,
  imageUrl: '',
  types: ['water'],
);
const starters = [bulbasaur, charmander, squirtle];

/// The real app, with the network service swapped for [service].
Widget appWith(PokemonService service) {
  return ProviderScope(
    overrides: [pokemonServiceProvider.overrideWithValue(service)],
    child: const PokedexApp(),
  );
}
