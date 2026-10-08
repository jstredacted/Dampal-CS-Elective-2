import 'dart:async';
import 'dart:convert';

import 'package:dampal_cs_elective_2/providers/pokemon_provider.dart';
import 'package:dampal_cs_elective_2/services/pokemon_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'Provider owns loading, success, refresh and read-only Pokémon',
    () async {
      final pending = Completer<http.Response>();
      var calls = 0;
      final client = MockClient((request) {
        calls++;
        expect(request.url.queryParameters['limit'], '30');
        return pending.future;
      });
      final provider = PokemonProvider(service: PokemonService(client: client));
      addTearDown(client.close);
      addTearDown(provider.dispose);
      final states = <PokemonStatus>[];
      provider.addListener(() => states.add(provider.status));
      final fetch = provider.fetchPokemon();
      await provider.fetchPokemon();
      await Future<void>.delayed(Duration.zero);
      expect(provider.status, PokemonStatus.loading);
      expect(calls, 1);
      pending.complete(
        http.Response(
          jsonEncode({
            'results': [
              {
                'name': 'bulbasaur',
                'url': 'https://pokeapi.co/api/v2/pokemon/1/',
              },
            ],
          }),
          200,
        ),
      );
      await fetch;
      expect(states, [PokemonStatus.loading, PokemonStatus.success]);
      expect(provider.pokemon.single.id, 1);
      expect(provider.pokemon.single.imageUrl, endsWith('/1.png'));
      expect(() => provider.pokemon.clear(), throwsUnsupportedError);
      await provider.fetchPokemon();
      expect(calls, 2);
      expect(provider.error, isNull);
    },
  );

  test('Provider reports errors and recovers to an empty success', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return calls == 1
          ? http.Response('Failure', 500)
          : http.Response('{"results":[]}', 200);
    });
    final provider = PokemonProvider(service: PokemonService(client: client));
    addTearDown(client.close);
    addTearDown(provider.dispose);
    await provider.fetchPokemon();
    expect(provider.status, PokemonStatus.error);
    expect(provider.error, isNotNull);
    await provider.fetchPokemon();
    expect(provider.status, PokemonStatus.success);
    expect(provider.error, isNull);
    expect(provider.pokemon, isEmpty);
  });

  for (final fails in [false, true]) {
    test(
      'late ${fails ? "error" : "success"} is safe after disposal',
      () async {
        final pending = Completer<http.Response>();
        final client = MockClient((_) => pending.future);
        addTearDown(client.close);
        final provider = PokemonProvider(
          service: PokemonService(client: client),
        );
        final fetch = provider.fetchPokemon();
        provider.dispose();
        pending.complete(http.Response('{"results":[]}', fails ? 500 : 200));
        await expectLater(fetch, completes);
        await expectLater(provider.fetchPokemon(), completes);
      },
    );
  }
}
