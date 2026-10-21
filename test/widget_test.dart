import 'dart:async';

import 'package:dampal_cs_elective_2/models/pokemon.dart';
import 'package:dampal_cs_elective_2/screens/pokemon_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

Finder cardHeart(String name) => find.descendant(
  of: find.ancestor(of: find.text(name), matching: find.byType(Card)),
  matching: find.byType(IconButton),
);

Future<void> openDetail(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  expect(find.byType(PokemonDetailScreen), findsOneWidget);
}

void main() {
  testWidgets('shows loading until the Future completes', (tester) async {
    final pending = Completer<List<Pokemon>>();
    final service = FakePokemonService(() => pending.future);
    await tester.pumpWidget(appWith(service));
    await tester.pump();
    expect(find.text('Loading Pokémon…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No Pokémon found.'), findsOneWidget);
    expect(service.calls, 1);
  });

  testWidgets('shows a meaningful error and retries', (tester) async {
    var attempts = 0;
    final service = FakePokemonService(() {
      attempts++;
      if (attempts == 1) {
        return Future.error(Exception('Could not connect to PokéAPI.'));
      }
      return Future.value(starters);
    });
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load Pokémon.'), findsOneWidget);
    expect(find.text('Could not connect to PokéAPI.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('bulbasaur'), findsOneWidget);
    expect(service.calls, 2);
  });

  testWidgets('refresh button calls fetchPokemon again', (tester) async {
    final pending = Completer<List<Pokemon>>();
    var attempts = 0;
    final service = FakePokemonService(() {
      attempts++;
      return attempts == 1 ? Future.value(starters) : pending.future;
    });
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Refresh Pokémon'));
    await tester.pump();
    expect(find.text('Loading Pokémon…'), findsOneWidget);
    final refresh = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.refresh),
    );
    expect(refresh.onPressed, isNull);

    pending.complete(starters);
    await tester.pumpAndSettle();
    expect(find.text('squirtle'), findsOneWidget);
    expect(service.calls, 2);
  });

  testWidgets('pull-to-refresh calls fetchPokemon again', (tester) async {
    final service = FakePokemonService(() async => starters);
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();

    await tester.fling(find.text('bulbasaur'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(service.calls, 2);
    expect(find.text('bulbasaur'), findsOneWidget);
  });

  testWidgets('type filter shows matching Pokémon and clears', (tester) async {
    await tester.pumpWidget(appWith(FakePokemonService(() async => starters)));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'fire'));
    await tester.pumpAndSettle();
    expect(find.text('charmander'), findsOneWidget);
    expect(find.text('bulbasaur'), findsNothing);
    expect(find.text('squirtle'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('bulbasaur'), findsOneWidget);
    expect(find.text('squirtle'), findsOneWidget);
  });

  testWidgets('a type with no matches after refresh offers Clear filter', (
    tester,
  ) async {
    var attempts = 0;
    final service = FakePokemonService(() async {
      attempts++;
      return attempts == 1 ? starters : const [bulbasaur, squirtle];
    });
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'fire'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Refresh Pokémon'));
    await tester.pumpAndSettle();
    expect(find.text('No fire Pokémon found.'), findsOneWidget);

    await tester.tap(find.text('Clear filter'));
    await tester.pumpAndSettle();
    expect(find.text('bulbasaur'), findsOneWidget);
  });

  testWidgets('heart toggles favorite on the card and in the panel', (
    tester,
  ) async {
    await tester.pumpWidget(appWith(FakePokemonService(() async => starters)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Show favorites'));
    await tester.pumpAndSettle();
    expect(
      find.text('No favorite Pokémon yet. Tap a heart to add one.'),
      findsOneWidget,
    );

    await tester.tap(cardHeart('charmander'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites (1)'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'charmander'), findsOneWidget);
    expect(
      find.descendant(
        of: cardHeart('charmander'),
        matching: find.byIcon(Icons.favorite),
      ),
      findsOneWidget,
    );

    await tester.tap(cardHeart('charmander'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites (0)'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'charmander'), findsNothing);

    await tester.tap(find.byTooltip('Hide favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites (0)'), findsNothing);
  });

  testWidgets('favorites panel stays open on the detail screen', (
    tester,
  ) async {
    await tester.pumpWidget(appWith(FakePokemonService(() async => starters)));
    await tester.pumpAndSettle();
    await tester.tap(cardHeart('squirtle'));
    await tester.tap(find.byTooltip('Show favorites'));
    await tester.pumpAndSettle();

    await openDetail(tester, 'bulbasaur');
    expect(find.text('Favorites (1)'), findsOneWidget);

    await tester.tap(find.text('Add to favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites (2)'), findsOneWidget);
    expect(find.text('Remove from favorites'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: cardHeart('bulbasaur'),
        matching: find.byIcon(Icons.favorite),
      ),
      findsOneWidget,
    );
  });

  testWidgets('nickname can be saved, edited, and removed', (tester) async {
    await tester.pumpWidget(appWith(FakePokemonService(() async => starters)));
    await tester.pumpAndSettle();
    await openDetail(tester, 'charmander');

    await tester.tap(find.text('Add nickname'));
    await tester.pumpAndSettle();
    expect(find.text('Remove'), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter a nickname first.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  Blaze ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Blaze'), findsWidgets);
    expect(find.text('Original name: charmander'), findsOneWidget);

    await tester.tap(find.text('Edit nickname'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Blaze'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ember');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Ember'), findsOneWidget);
    expect(find.text('charmander'), findsOneWidget);

    await openDetail(tester, 'Ember');
    await tester.tap(find.text('Edit nickname'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Ember'), findsNothing);
    expect(find.text('Add nickname'), findsOneWidget);
  });

  testWidgets('cancel leaves the nickname unchanged', (tester) async {
    await tester.pumpWidget(appWith(FakePokemonService(() async => starters)));
    await tester.pumpAndSettle();
    await openDetail(tester, 'squirtle');
    await tester.tap(find.text('Add nickname'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Shelly');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Shelly'), findsNothing);
    expect(find.text('Add nickname'), findsOneWidget);
  });

  for (final width in [320.0, 600.0, 840.0, 1200.0]) {
    testWidgets('scrolls through 30 cards at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pokemon = List.generate(
        30,
        (i) => Pokemon(
          name: 'pokemon-${i + 1}',
          id: i + 1,
          imageUrl: '',
          types: const ['normal', 'flying'],
        ),
      );
      final service = FakePokemonService(() async => pokemon);
      await tester.pumpWidget(appWith(service));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('pokemon-30'),
        400,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('#030'), findsOneWidget);
      expect(service.calls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('safe to remove the app while loading', (tester) async {
    final pending = Completer<List<Pokemon>>();
    await tester.pumpWidget(appWith(FakePokemonService(() => pending.future)));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(starters);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
