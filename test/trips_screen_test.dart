import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_data.dart';
import 'package:smart_travel_assistant/features/accounts/accounts_provider.dart';
import 'package:smart_travel_assistant/features/itinerary/destination_lookup.dart';
import 'package:smart_travel_assistant/features/itinerary/itinerary_provider.dart';
import 'package:smart_travel_assistant/features/itinerary/trips_screen.dart';
import 'package:smart_travel_assistant/theme/meridian_theme.dart';

// The Trips screen inside just the providers it needs, with a stand-in
// for Nominatim so no test touches the network.
Widget _app({LookUpDestination? lookUp}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AccountsProvider()),
      ChangeNotifierProvider(create: (_) => ItineraryProvider()),
    ],
    child: MaterialApp(
      theme: meridianTheme(Brightness.dark),
      home: Scaffold(body: TripsScreen(lookUp: lookUp)),
    ),
  );
}

Future<void> _pickDay(WidgetTester tester, String field, String day) async {
  await tester.tap(find.text(field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(day).last);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    debugUseFakeData = true;
    resetFakeTrips();
  });
  tearDown(() => debugUseFakeData = null);

  test('days to go counts whole days from today to the start', () {
    expect(daysUntil(DateTime(2026, 11, 20), today: DateTime(2026, 10, 14)), 37);
    expect(daysUntil(DateTime(2026, 11, 20), today: DateTime(2026, 11, 20)), 0);
    expect(daysUntil(DateTime(2026, 3, 1), today: DateTime(2026, 10, 14)), isNegative);
  });

  testWidgets('shows the demo trip under the Trips heading', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Bangalore'), findsOneWidget);
  });

  testWidgets('Create with nothing filled in shows the errors and saves nothing', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create trip'));
    await tester.pumpAndSettle();

    expect(find.text('Enter where you are going.'), findsOneWidget);
    expect(find.text('Pick the day you leave.'), findsOneWidget);
    expect(fakeTrips, hasLength(1));
  });

  testWidgets('a new trip is looked up, saved, and its empty days shown', (tester) async {
    String? lookedUp;
    Future<DestinationMatch?> fakeLookUp(String name) async {
      lookedUp = name;
      return const DestinationMatch(name: 'Goa, India', latitude: 15.3, longitude: 74.08);
    }

    await tester.pumpWidget(_app(lookUp: fakeLookUp));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New trip'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Goa');
    await _pickDay(tester, 'Leave on', '20');
    await _pickDay(tester, 'Come back on', '22');
    await tester.tap(find.text('Create trip'));
    await tester.pumpAndSettle();

    expect(lookedUp, 'Goa');
    final saved = fakeTrips.last;
    expect(saved.destination, 'Goa');
    expect(saved.latitude, 15.3);
    expect(saved.numberOfDays, 3);
    // Scene 3: the new trip opens with its days worked out from the dates.
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Day 3'), findsOneWidget);
    expect(find.text('No stops yet'), findsNWidgets(3));
  });
}
