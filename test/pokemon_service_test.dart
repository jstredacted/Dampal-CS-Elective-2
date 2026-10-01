import 'dart:async';
import 'dart:convert';

import 'package:dampal_cs_elective_2/models/pokemon.dart';
import 'package:dampal_cs_elective_2/services/pokemon_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Map<String, dynamic> entry(int id) => {
    'name': 'pokemon-$id',
    'url': 'https://pokeapi.co/api/v2/pokemon/$id/',
  };

  test('model parses API identity and creates matching sprite URL', () {
    final pokemon = Pokemon.fromJson(entry(25));
    expect(pokemon.id, 25);
    expect(pokemon.name, 'pokemon-25');
    expect(pokemon.imageUrl, endsWith('/25.png'));
    expect(
      Pokemon.fromJson({
        'name': 'pikachu',
        'url': 'https://pokeapi.co/api/v2/pokemon/25',
      }).id,
      25,
    );
  });

  test('model rejects missing or malformed identity', () {
    for (final json in [
      <String, dynamic>{},
      {'name': '', 'url': 'https://pokeapi.co/api/v2/pokemon/1/'},
      {'name': 'bad', 'url': 'https://pokeapi.co/api/v2/pokemon/no-id/'},
      {'name': 'bad', 'url': 'https://pokeapi.co/api/v2/pokemon/0/'},
      {'name': 'bad', 'url': 'https://pokeapi.co/api/v2/pokemon/-1/'},
      {'name': 1, 'url': 25},
    ]) {
      expect(() => Pokemon.fromJson(json), throwsFormatException);
    }
  });

  test('requests exactly 30 from offset zero and preserves order', () async {
    final client = MockClient((request) async {
      expect(request.url.scheme, 'https');
      expect(request.url.host, 'pokeapi.co');
      expect(request.url.path, '/api/v2/pokemon');
      expect(request.url.queryParameters, {'limit': '30', 'offset': '0'});
      return http.Response(
        jsonEncode({'results': List.generate(30, (i) => entry(i + 1))}),
        200,
      );
    });
    addTearDown(client.close);
    final pokemon = await PokemonService(client: client).fetchPokemon();
    expect(pokemon.length, 30);
    expect(pokemon.first.id, 1);
    expect(pokemon.last.id, 30);
  });

  test('caps an oversized API response at 30', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'results': List.generate(35, (i) => entry(i + 1))}),
        200,
      ),
    );
    addTearDown(client.close);
    expect(await PokemonService(client: client).fetchPokemon(), hasLength(30));
  });

  test(
    'preserves empty results instead of reporting a request failure',
    () async {
      final client = MockClient(
        (_) async => http.Response('{"results":[]}', 200),
      );
      addTearDown(client.close);
      expect(await PokemonService(client: client).fetchPokemon(), isEmpty);
    },
  );

  for (final body in [
    'bad-json',
    '[]',
    '{}',
    '{"results":{}}',
    '{"results":[null]}',
  ]) {
    test('rejects malformed response $body', () async {
      final client = MockClient((_) async => http.Response(body, 200));
      addTearDown(client.close);
      await expectLater(
        PokemonService(client: client).fetchPokemon(),
        throwsFormatException,
      );
    });
  }

  for (final code in [403, 404, 500]) {
    test('reports HTTP $code as an error', () async {
      final client = MockClient((_) async => http.Response('Failure', code));
      addTearDown(client.close);
      await expectLater(
        PokemonService(client: client).fetchPokemon(),
        throwsException,
      );
    });
  }

  test('reports network failure', () async {
    final client = MockClient(
      (_) async => throw http.ClientException('Offline'),
    );
    addTearDown(client.close);
    await expectLater(
      PokemonService(client: client).fetchPokemon(),
      throwsException,
    );
  });

  test('reports request timeout', () async {
    final client = MockClient((_) async => throw TimeoutException('Timed out'));
    addTearDown(client.close);
    await expectLater(
      PokemonService(client: client).fetchPokemon(),
      throwsException,
    );
  });
}
