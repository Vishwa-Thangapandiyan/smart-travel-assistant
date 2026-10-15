import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_data.dart';
import 'package:smart_travel_assistant/services/offline_service.dart' show resetFakeDownloads;
import 'package:smart_travel_assistant/features/itinerary/day_screen.dart';
import 'package:smart_travel_assistant/features/itinerary/destination_lookup.dart';
import 'package:smart_travel_assistant/features/itinerary/itinerary_provider.dart';
import 'package:smart_travel_assistant/features/itinerary/stays_provider.dart';
import 'package:smart_travel_assistant/features/offline/offline_provider.dart';
import 'package:smart_travel_assistant/features/recommendations/stop_photos.dart';
import 'package:smart_travel_assistant/theme/meridian_theme.dart';
import 'package:smart_travel_assistant/widgets/web_photo.dart';

String? _searchedFor;

Future<List<DestinationMatch>> _fakeLookUp(String query) async {
  _searchedFor = query;
  return const [
    DestinationMatch(name: 'Vidhana Soudha, Bengaluru, Karnataka, India', latitude: 12.9796, longitude: 77.5907),
  ];
}

Widget _app(ItineraryProvider provider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider(create: (_) => OfflineProvider()),
      ChangeNotifierProvider(create: (_) => StaysProvider()),
    ],
    child: MaterialApp(
      theme: meridianTheme(Brightness.dark),
      home: DayScreen(trip: demoTrip, lookUp: _fakeLookUp),
    ),
  );
}

// The stop names on screen, top to bottom.
List<String> _stopsOnScreen(WidgetTester tester, ItineraryProvider provider, int day) {
  return [
    for (final stop in provider.stopsForDay(day))
      if (find.text(stop.title).evaluate().isNotEmpty) stop.title,
  ];
}

void main() {
  late ItineraryProvider provider;

  setUp(() async {
    debugUseFakeData = true;
    await resetFakeDownloads();
    resetFakeTrips();
    provider = ItineraryProvider();
  });
  tearDown(() => debugUseFakeData = null);

  Future<void> openDay2(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sat 21'));
    await tester.pumpAndSettle();
  }

  test('a stop matches a seeded place by name; a stop that is not one has no photo', () async {
    final photos = await placePhotosFor('Bengaluru');

    expect(photoForStop(demoItems.first, photos), isNotNull); // Vidhana Soudha
    expect(photoForStop(demoItems.last, photos), isNull); // the airport isn't seeded
  });

  testWidgets('stops that are seeded places show their photo', (tester) async {
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    // Day 1 is Vidhana Soudha and Vidyarthi Bhavan, both seeded places.
    expect(find.byType(WebPhoto), findsNWidgets(2));
  });

  testWidgets('opens on day 1 and switches days from the pill', (tester) async {
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    expect(find.text('DAY 1 · 2 STOPS'), findsOneWidget);
    expect(find.text('Vidhana Soudha'), findsOneWidget);

    await tester.tap(find.text('Sat 21'));
    await tester.pumpAndSettle();

    expect(find.text('Saturday, 21 Nov'), findsOneWidget);
    expect(find.text('DAY 2 · 5 STOPS'), findsOneWidget);
    expect(find.text('Bangalore Palace'), findsOneWidget);
    expect(find.text('12:30'), findsOneWidget);
  });

  testWidgets('the down arrow moves a stop one place later', (tester) async {
    await openDay2(tester);

    await tester.tap(find.byTooltip('Move down').first);
    await tester.pumpAndSettle();

    expect(_stopsOnScreen(tester, provider, 2).take(2), ['Lalbagh Botanical Garden', 'MTR, Lalbagh Road']);
    final mtrY = tester.getTopLeft(find.text('MTR, Lalbagh Road')).dy;
    final lalbaghY = tester.getTopLeft(find.text('Lalbagh Botanical Garden')).dy;
    expect(lalbaghY, lessThan(mtrY));
  });

  testWidgets('editing a stop saves new notes', (tester) async {
    await openDay2(tester);

    await tester.tap(find.text('Cubbon Park'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Notes (optional)'), 'Library closes at 6');
    await tester.tap(find.text('Save stop'));
    await tester.pumpAndSettle();

    expect(find.text('Library closes at 6'), findsOneWidget);
  });

  testWidgets('a new stop is searched inside the trip city and added at the end', (tester) async {
    await openDay2(tester);

    await tester.tap(find.text('Add a stop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save stop'));
    await tester.pumpAndSettle();
    expect(find.text('Give the stop a name.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Stop name'), 'Evening walk');
    await tester.enterText(find.widgetWithText(TextField, 'Place (to show it on the map)'), 'Vidhana Soudha');
    await tester.tap(find.byTooltip('Search place'));
    await tester.pumpAndSettle();
    expect(_searchedFor, 'Vidhana Soudha, Bangalore');

    await tester.tap(find.text('Save stop'));
    await tester.pumpAndSettle();

    expect(find.text('DAY 2 · 6 STOPS'), findsOneWidget);
    final added = provider.stopsForDay(2).last;
    expect(added.title, 'Evening walk');
    expect(added.latitude, 12.9796);
  });

  testWidgets('where you stay is searched inside the trip city and shown on the day', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add where you\'re staying'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Vidhana Soudha');
    await tester.tap(find.byTooltip('Search place'));
    await tester.pumpAndSettle();
    expect(_searchedFor, 'Vidhana Soudha, Bangalore');
    await tester.tap(find.text('Save stay'));
    await tester.pumpAndSettle();

    expect(find.text('Vidhana Soudha'), findsWidgets); // the stay, and Day 1's first stop
    expect(find.text('Change stay'), findsOneWidget);
  });

  testWidgets('a stop can be deleted after confirming', (tester) async {
    await openDay2(tester);

    await tester.tap(find.text('Church Street'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete stop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Church Street'), findsNothing);
    expect(find.text('DAY 2 · 4 STOPS'), findsOneWidget);
  });

  testWidgets('the trip can be downloaded, then its saved copy opened', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    expect(find.text('Open saved copy'), findsNothing);
    await tester.tap(find.text('Download for offline'));
    await tester.pumpAndSettle();

    expect(find.text('Downloaded ✓'), findsOneWidget);
    await tester.tap(find.text('Open saved copy'));
    await tester.pumpAndSettle();

    expect(find.text('Saved trip'), findsOneWidget);
  });
}
