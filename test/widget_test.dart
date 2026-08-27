import 'package:dampal_cs_elective_2/dashboard_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies centralized responsive breakpoints', () {
    expect(deviceTypeOf(599), DeviceType.compact);
    expect(deviceTypeOf(600), DeviceType.medium);
    expect(deviceTypeOf(839), DeviceType.medium);
    expect(deviceTypeOf(840), DeviceType.expanded);
    expect(deviceTypeOf(1199), DeviceType.expanded);
    expect(deviceTypeOf(1200), DeviceType.large);
  });

  testWidgets('uses compact mobile dashboard layout', (tester) async {
    await _pumpDashboard(tester, const Size(390, 844));

    expect(find.byKey(const ValueKey('compact-layout')), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-navigation-rail')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('dashboard-side-pane')), findsNothing);

    final firstCard = tester.getTopLeft(
      find.byKey(const ValueKey('metric-card-0')),
    );
    final thirdCard = tester.getTopLeft(
      find.byKey(const ValueKey('metric-card-2')),
    );
    expect(thirdCard.dy, greaterThan(firstCard.dy));

    await tester.tap(find.byKey(const ValueKey('dashboard-updates-switch')));
    await tester.pump();

    final adaptiveSwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('dashboard-updates-switch')),
    );
    expect(adaptiveSwitch.value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses medium tablet dashboard layout', (tester) async {
    await _pumpDashboard(tester, const Size(700, 900));

    expect(find.byKey(const ValueKey('medium-layout')), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-side-pane')), findsNothing);

    final firstCard = tester.getTopLeft(
      find.byKey(const ValueKey('metric-card-0')),
    );
    final fourthCard = tester.getTopLeft(
      find.byKey(const ValueKey('metric-card-3')),
    );
    expect(fourthCard.dy, firstCard.dy);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses expanded desktop dashboard layout', (tester) async {
    await _pumpDashboard(tester, const Size(1200, 800));

    expect(find.byKey(const ValueKey('expanded-layout')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-navigation-rail')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('dashboard-drawer')), findsNothing);
    expect(find.byKey(const ValueKey('dashboard-side-pane')), findsOneWidget);

    await tester.tap(find.text('Settings').first);
    await tester.pump();

    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDashboard(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const DashboardApp());
  await tester.pump();
}
