import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

class PokemonService {
  PokemonService({this.client});

  final http.Client? client;

  /// Loads the first 30 Pokémon, then their details (for type data) in parallel.
  Future<List<Pokemon>> fetchPokemon() async {
    final uri = Uri.https('pokeapi.co', '/api/v2/pokemon', <String, String>{
      'limit': '30',
      'offset': '0',
    });

    final requestClient = client ?? http.Client();
    try {
      final decoded = await _getJson(requestClient, uri);

      final results = decoded['results'];
      if (results is! List) {
        throw const FormatException('The API response has no Pokémon list.');
      }

      final ids = results.take(30).map((item) {
        if (item is! Map<String, dynamic> || item['url'] is! String) {
          throw const FormatException('A Pokémon result was invalid.');
        }
        return Pokemon.idFromUrl(item['url'] as String);
      }).toList();

      // The detail calls do not depend on each other, so they run together.
      return await Future.wait(
        ids.map((id) async {
          final detail = await _getJson(
            requestClient,
            Uri.https('pokeapi.co', '/api/v2/pokemon/$id'),
          );
          return Pokemon.fromJson(detail);
        }),
      );
    } on TimeoutException {
      throw Exception('The request timed out. Please try again.');
    } on http.ClientException {
      throw Exception('Could not connect to PokéAPI. Please try again.');
    } finally {
      if (client == null) {
        requestClient.close();
      }
    }
  }

  Future<Map<String, dynamic>> _getJson(http.Client client, Uri uri) async {
    final response = await client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('PokéAPI returned status code ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The API response was not an object.');
    }
    return decoded;
  }
}
