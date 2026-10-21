import 'dart:async';
import 'dart:convert';

import 'package:dampal_cs_elective_2/models/pokemon.dart';
import 'package:dampal_cs_elective_2/services/pokemon_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> entry(int id) => {
  'name': 'pokemon-$id',
  'url': 'https://pokeapi.co/api/v2/pokemon/$id/',
};

Map<String, dynamic> detail(int id, [List<String> types = const ['normal']]) =>
    {
      'id': id,
      'name': 'pokemon-$id',
      'types': [
        for (var i = 0; i < types.length; i++)
          {
            'slot': i + 1,
            'type': {'name': types[i], 'url': ''},
          },
      ],
    };

/// Answers the list request with [count] entries and each detail request
/// with [detail] data.
MockClient pokeApi(int count, {String? listBody}) {
  return MockClient((request) async {
    if (request.url.path == '/api/v2/pokemon') {
      return http.Response(
        listBody ??
            jsonEncode({'results': List.generate(count, (i) => entry(i + 1))}),
        200,
      );
    }
    final id = int.parse(request.url.pathSegments.last);
    return http.Response(jsonEncode(detail(id, ['grass', 'poison'])), 200);
  });
}

void main() {
  test('model parses detail JSON with types and sprite URL', () {
    final pokemon = Pokemon.fromJson(detail(25, ['electric']));
    expect(pokemon.id, 25);
    expect(pokemon.name, 'pokemon-25');
    expect(pokemon.types, ['electric']);
    expect(pokemon.imageUrl, endsWith('/25.png'));
  });

  test('model rejects missing or malformed detail data', () {
    for (final json in [
      <String, dynamic>{},
      {'id': 1, 'name': '', 'types': []},
      {'id': 0, 'name': 'bad', 'types': []},
      {'id': '1', 'name': 'bad', 'types': []},
      {'id': 1, 'name': 'bad'},
      {
        'id': 1,
        'name': 'bad',
        'types': [
          {'type': 5},
        ],
      },
    ]) {
      expect(() => Pokemon.fromJson(json), throwsFormatException);
    }
  });

  test('reads IDs from list URLs with or without a trailing slash', () {
    expect(Pokemon.idFromUrl('https://pokeapi.co/api/v2/pokemon/25/'), 25);
    expect(Pokemon.idFromUrl('https://pokeapi.co/api/v2/pokemon/25'), 25);
    expect(
      () => Pokemon.idFromUrl('https://pokeapi.co/api/v2/pokemon/0/'),
      throwsFormatException,
    );
  });

  test('requests 30 from offset zero, then every detail, in order', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path == '/api/v2/pokemon') {
        expect(request.url.queryParameters, {'limit': '30', 'offset': '0'});
        return http.Response(
          jsonEncode({'results': List.generate(30, (i) => entry(i + 1))}),
          200,
        );
      }
      final id = int.parse(request.url.pathSegments.last);
      return http.Response(jsonEncode(detail(id, ['fire'])), 200);
    });
    addTearDown(client.close);
    final pokemon = await PokemonService(client: client).fetchPokemon();
    expect(pokemon.length, 30);
    expect(pokemon.first.id, 1);
    expect(pokemon.last.id, 30);
    expect(pokemon.first.types, ['fire']);
    expect(paths.first, '/api/v2/pokemon');
    expect(paths.where((p) => p.startsWith('/api/v2/pokemon/')), hasLength(30));
  });

  test('caps an oversized API response at 30', () async {
    final client = pokeApi(35);
    addTearDown(client.close);
    expect(await PokemonService(client: client).fetchPokemon(), hasLength(30));
  });

  test('returns an empty list for empty results', () async {
    final client = pokeApi(0, listBody: '{"results":[]}');
    addTearDown(client.close);
    expect(await PokemonService(client: client).fetchPokemon(), isEmpty);
  });

  for (final body in [
    'bad-json',
    '[]',
    '{}',
    '{"results":{}}',
    '{"results":[null]}',
  ]) {
    test('rejects malformed list response $body', () async {
      final client = pokeApi(0, listBody: body);
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

  test('one failed detail request fails the whole load', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/v2/pokemon') {
        return http.Response(
          jsonEncode({'results': List.generate(3, (i) => entry(i + 1))}),
          200,
        );
      }
      if (request.url.pathSegments.last == '2') {
        return http.Response('Failure', 500);
      }
      final id = int.parse(request.url.pathSegments.last);
      return http.Response(jsonEncode(detail(id)), 200);
    });
    addTearDown(client.close);
    await expectLater(
      PokemonService(client: client).fetchPokemon(),
      throwsException,
    );
  });

  test('reports network failure', () async {
    final client = MockClient(
      (_) async => throw http.ClientException('Offline'),
    );
    addTearDown(client.close);
    await expectLater(
      PokemonService(client: client).fetchPokemon(),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Could not connect'),
        ),
      ),
    );
  });

  test('reports request timeout', () async {
    final client = MockClient((_) async => throw TimeoutException('Timed out'));
    addTearDown(client.close);
    await expectLater(
      PokemonService(client: client).fetchPokemon(),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('timed out'),
        ),
      ),
    );
  });
}
