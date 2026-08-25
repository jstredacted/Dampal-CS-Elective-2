import 'package:dampal_cs_elective_2/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigates between Instagram tabs', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const InstagramUiApp());

    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('username'), findsOneWidget);
    expect(find.text('10,547 likes'), findsOneWidget);
    expect(find.textContaining('Lorem ipsum'), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.add_box_outlined), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-/search')));
    await tester.pumpAndSettle();

    expect(find.text('Search'), findsOneWidget);
    expect(find.text('10,547 likes'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('navigation-/profile')));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-/')));
    await tester.pumpAndSettle();

    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('10,547 likes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
