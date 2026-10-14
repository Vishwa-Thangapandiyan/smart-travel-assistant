import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/main.dart';

void main() {
  late Box<String> settings;

  // In memory (bytes:), so nothing is written to disk during the tests.
  setUpAll(() async => settings = await Hive.openBox<String>('settings', bytes: Uint8List(0)));

  setUp(() => debugUseFakeData = true);
  tearDown(() => debugUseFakeData = null);

  testWidgets('with no Supabase config the app opens on the Trips tab', (tester) async {
    await tester.pumpWidget(MeridianApp(settings: settings));
    await tester.pumpAndSettle();

    expect(find.text('Trips'), findsWidgets);
  });

  testWidgets('every tab opens its screen and SOS is always one tap away', (tester) async {
    await tester.pumpWidget(MeridianApp(settings: settings));
    await tester.pumpAndSettle();

    // What each tab shows that no other tab does. The Map has no title —
    // it is all map — but always shows the OpenStreetMap credit.
    const marks = {
      'Map': '© OpenStreetMap contributors',
      'Budget': 'Budget',
      'Explore': 'Worth a look in',
      'Trips': 'Trips',
    };
    for (final tab in marks.keys) {
      await tester.tap(find.byTooltip(tab));
      await tester.pumpAndSettle();

      expect(find.text(marks[tab]!), findsOneWidget, reason: '$tab screen should be showing');
      expect(find.bySemanticsLabel('Emergency help'), findsOneWidget, reason: 'SOS missing on $tab');
    }
  });

  testWidgets('tapping SOS opens the help screen', (tester) async {
    await tester.pumpWidget(MeridianApp(settings: settings));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Emergency help'));
    await tester.pumpAndSettle();

    expect(find.text('Get help'), findsOneWidget);
  });

  testWidgets('Day in the Account sheet turns the whole app to the day look', (tester) async {
    await tester.pumpWidget(MeridianApp(settings: settings));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
  });
}
