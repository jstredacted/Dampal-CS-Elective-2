class Pokemon {
  const Pokemon({required this.name, required this.id, required this.imageUrl});

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final url = json['url'];

    if (name is! String || name.trim().isEmpty || url is! String) {
      throw const FormatException('Invalid Pokémon data.');
    }

    final id = _idFromUrl(url);

    return Pokemon(
      name: name,
      id: id,
      imageUrl:
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
    );
  }

  final String name;
  final int id;
  final String imageUrl;

  static int _idFromUrl(String url) {
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
