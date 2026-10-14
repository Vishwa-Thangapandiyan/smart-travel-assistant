import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_data.dart';
import 'package:smart_travel_assistant/features/accounts/accounts_provider.dart';
import 'package:smart_travel_assistant/features/itinerary/day_screen.dart';
import 'package:smart_travel_assistant/features/itinerary/destination_lookup.dart';
import 'package:smart_travel_assistant/features/itinerary/itinerary_provider.dart';
import 'package:smart_travel_assistant/features/recommendations/recommendations_provider.dart';
import 'package:smart_travel_assistant/features/recommendations/recommendations_screen.dart';
import 'package:smart_travel_assistant/theme/meridian_theme.dart';

Future<List<DestinationMatch>> _noLookUp(String _) async => [];

Widget _app(ItineraryProvider itinerary, Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AccountsProvider()),
      ChangeNotifierProvider.value(value: itinerary),
      ChangeNotifierProvider(create: (_) => RecommendationsProvider()),
    ],
    child: MaterialApp(theme: meridianTheme(Brightness.dark), home: home),
  );
}

void main() {
  late ItineraryProvider itinerary;

  setUp(() {
    debugUseFakeData = true;
    resetFakeTrips();
    itinerary = ItineraryProvider();
  });
  tearDown(() => debugUseFakeData = null);

  Future<void> show(WidgetTester tester, Widget home) async {
    await tester.binding.setSurfaceSize(const Size(420, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(itinerary, home));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the next trip\'s destination, highest rated first', (tester) async {
    await show(tester, const Scaffold(body: RecommendationsScreen()));

    expect(find.text('Bangalore'), findsOneWidget);
    expect(find.text('13 PLACES'), findsOneWidget);
    expect(find.text('HIGHEST RATED FIRST'), findsOneWidget);
    expect(find.text('ISKCON Temple Bangalore'), findsOneWidget);
  });

  testWidgets('the Food chip leaves only restaurants', (tester) async {
    await show(tester, const Scaffold(body: RecommendationsScreen()));

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    expect(find.text('3 PLACES'), findsOneWidget);
    expect(find.text('Toit'), findsOneWidget);
    expect(find.text('Cubbon Park'), findsNothing);
  });

  testWidgets('+ asks which day, adds the place there, and marks the card', (tester) async {
    await show(tester, const Scaffold(body: RecommendationsScreen()));
    // Day 3 already has two seeded places (Tipu Sultan's Summer Palace,
    // Commercial Street), so their cards say "On Sun 22" already.
    expect(find.text('On Sun 22 ✓'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Add Toit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day 3'));
    await tester.pumpAndSettle();

    final added = itinerary.stopsForDay(3).last;
    expect(added.title, 'Toit');
    expect(added.latitude, isNotNull);
    expect(find.text('On Sun 22 ✓'), findsNWidgets(3));
  });

  testWidgets('From suggestions on a day adds straight to that day', (tester) async {
    await show(tester, DayScreen(trip: demoTrip, lookUp: _noLookUp));

    await tester.tap(find.text('Sat 21'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('From suggestions'));
    await tester.pumpAndSettle();
    expect(find.text('Add to Day 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Add Vidyarthi Bhavan'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('DAY 2 · 6 STOPS'), findsOneWidget);
    expect(find.text('Vidyarthi Bhavan'), findsOneWidget);
  });
}
