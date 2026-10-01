import 'dart:async';

import 'package:dampal_cs_elective_2/main.dart';
import 'package:dampal_cs_elective_2/models/pokemon.dart';
import 'package:dampal_cs_elective_2/services/pokemon_service.dart';
import 'package:dampal_cs_elective_2/widgets/pokemon_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

const bulbasaur = Pokemon(name: 'bulbasaur', id: 1, imageUrl: '');

void main() {
  testWidgets('shows loading until the Future completes', (tester) async {
    final pending = Completer<List<Pokemon>>();
    final service = FakePokemonService(() => pending.future);
    await tester.pumpWidget(PokedexApp(service: service));
    expect(find.text('Loading Pokémon…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No Pokémon found.'), findsOneWidget);
    expect(find.text('Loading Pokémon…'), findsNothing);
    expect(service.calls, 1);
  });

  testWidgets('shows an error and retries with a new Future', (tester) async {
    final retry = Completer<List<Pokemon>>();
    var attempts = 0;
    final service = FakePokemonService(() {
      attempts++;
      if (attempts == 1) return Future.error(Exception('Network error'));
      return retry.future;
    });
    await tester.pumpWidget(PokedexApp(service: service));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load Pokémon.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(find.text('Loading Pokémon…'), findsOneWidget);
    retry.complete([bulbasaur]);
    await tester.pumpAndSettle();
    expect(find.text('bulbasaur'), findsOneWidget);
    expect(find.text('#001'), findsOneWidget);
    expect(find.text('Unable to load Pokémon.'), findsNothing);
    expect(service.calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows empty results without a grid or error', (tester) async {
    await tester.pumpWidget(
      PokedexApp(service: FakePokemonService(() async => [])),
    );
    await tester.pumpAndSettle();
    expect(find.text('No Pokémon found.'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(find.text('Unable to load Pokémon.'), findsNothing);
  });

  for (final width in [320.0, 600.0, 840.0, 1200.0]) {
    testWidgets('scrolls through 30 cards at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pokemon = List.generate(
        30,
        (i) => Pokemon(name: 'pokemon-${i + 1}', id: i + 1, imageUrl: ''),
      );
      final service = FakePokemonService(() async => pokemon);
      await tester.pumpWidget(PokedexApp(service: service));
      await tester.pumpAndSettle();
      expect(find.text('#001'), findsOneWidget);
      final grid = tester.widget<GridView>(find.byType(GridView));
      expect(grid.childrenDelegate.estimatedChildCount, 30);
      await tester.scrollUntilVisible(
        find.text('pokemon-30'),
        400,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('#030'), findsOneWidget);
      await tester.tap(find.text('pokemon-30'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(service.calls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('resizing does not repeat the API call', (tester) async {
    final service = FakePokemonService(() async => [bulbasaur]);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(PokedexApp(service: service));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1000, 700);
    await tester.pumpAndSettle();
    expect(service.calls, 1);
    expect(find.text('bulbasaur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('image failure keeps name and ID readable', (tester) async {
    await tester.pumpWidget(
      PokedexApp(
        service: FakePokemonService(
          () async => [
            const Pokemon(
              name: 'bulbasaur',
              id: 1,
              imageUrl: 'https://example.com/missing.png',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.text('#001'), findsOneWidget);
    expect(find.text('bulbasaur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card supports enlarged text at phone width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 138,
                height: 250,
                child: PokemonCard(
                  pokemon: const Pokemon(
                    name: 'charmeleon',
                    id: 5,
                    imageUrl: '',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('charmeleon'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('safe to remove screen while loading', (tester) async {
    final pending = Completer<List<Pokemon>>();
    await tester.pumpWidget(
      PokedexApp(service: FakePokemonService(() => pending.future)),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete([bulbasaur]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
