import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

class PokemonService {
  PokemonService({this.client});

  final http.Client? client;

  Future<List<Pokemon>> fetchPokemon() async {
    final uri = Uri.https('pokeapi.co', '/api/v2/pokemon', <String, String>{
      'limit': '30',
      'offset': '0',
    });

    final requestClient = client ?? http.Client();
    try {
      final response = await requestClient
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('PokéAPI returned status code ${response.statusCode}.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('The API response was not an object.');
      }

      final results = decoded['results'];
      if (results is! List) {
        throw const FormatException('The API response has no Pokémon list.');
      }

      return results.take(30).map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('A Pokémon result was invalid.');
        }

        return Pokemon.fromJson(item);
      }).toList();
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
}
