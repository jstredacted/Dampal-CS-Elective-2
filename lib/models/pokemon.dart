class Pokemon {
  const Pokemon({
    required this.name,
    required this.id,
    required this.imageUrl,
    this.types = const [],
  });

  /// Parses one result from `/pokemon/{id}`, which includes the type data.
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final id = json['id'];
    final types = json['types'];

    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Invalid Pokémon name.');
    }
    if (id is! int || id <= 0) {
      throw const FormatException('Invalid Pokémon ID.');
    }
    if (types is! List) {
      throw const FormatException('Invalid Pokémon types.');
    }

    final typeNames = <String>[];
    for (final item in types) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid Pokémon type.');
      }
      final type = item['type'];
      if (type is! Map<String, dynamic> || type['name'] is! String) {
        throw const FormatException('Invalid Pokémon type.');
      }
      typeNames.add(type['name'] as String);
    }

    return Pokemon(
      name: name,
      id: id,
      imageUrl:
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
      types: typeNames,
    );
  }

  final String name;
  final int id;
  final String imageUrl;
  final List<String> types;

  /// Reads the ID from a list entry URL such as `.../pokemon/25/`.
  static int idFromUrl(String url) {
    final segments = url.split('/');

    for (final segment in segments.reversed) {
      if (segment.isEmpty) {
        continue;
      }

      final id = int.tryParse(segment);
      if (id != null && id > 0) {
        return id;
      }
      throw const FormatException('Invalid Pokémon ID.');
    }

    throw const FormatException('Could not find a Pokémon ID.');
  }
}
