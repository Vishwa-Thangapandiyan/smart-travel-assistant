import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_data.dart';
import 'package:smart_travel_assistant/features/accounts/accounts_provider.dart';
import 'package:smart_travel_assistant/features/itinerary/itinerary_provider.dart';
import 'package:smart_travel_assistant/features/maps/maps_screen.dart';
import 'package:smart_travel_assistant/theme/meridian_theme.dart';

Widget _app(ItineraryProvider itinerary, {double systemBarHeight = 0}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AccountsProvider()),
      ChangeNotifierProvider.value(value: itinerary),
    ],
    child: MaterialApp(
      theme: meridianTheme(Brightness.dark),
      // A phone's own button bar at the bottom of the screen.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: EdgeInsets.only(bottom: systemBarHeight)),
        child: child!,
      ),
      home: const Scaffold(body: MapsScreen(showTiles: false)),
    ),
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

  Future<void> show(WidgetTester tester, {double systemBarHeight = 0}) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(itinerary, systemBarHeight: systemBarHeight));
    await tester.pumpAndSettle();
  }

  testWidgets('with no trip open it opens the next trip and pins day 1', (tester) async {
    await show(tester);

    expect(itinerary.currentTrip?.destination, 'Bangalore');
    expect(find.bySemanticsLabel('Stop 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Stop 2'), findsOneWidget);
    expect(find.text('STOP 1 OF 2 · DAY 1'), findsOneWidget);
    expect(find.text('Vidhana Soudha'), findsOneWidget);
  });

  testWidgets('the route through the day is summed up on the card', (tester) async {
    await show(tester);

    expect(find.textContaining(' km · '), findsOneWidget);
    expect(find.textContaining('min · demo line'), findsOneWidget);
  });

  testWidgets('switching to day 2 pins its five stops; tapping a pin selects it', (tester) async {
    await show(tester);

    await tester.tap(find.text('Day 2'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Stop 5'), findsOneWidget);
    expect(find.text('MTR, Lalbagh Road'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Stop 3'));
    await tester.pumpAndSettle();
    expect(find.text('STOP 3 OF 5 · DAY 2'), findsOneWidget);
    expect(find.text('Bangalore Palace'), findsOneWidget);
    expect(find.text('12:30'), findsOneWidget);
  });

  testWidgets('a day with no placed stops says so instead of crashing', (tester) async {
    final goa = await itinerary.createTrip(
      userId: demoUserId,
      destination: 'Goa',
      start: DateTime(2027, 1, 10),
      end: DateTime(2027, 1, 11),
      match: null,
    );
    await itinerary.openTrip(goa);
    await itinerary.addStop(day: 1, title: 'Somewhere without a place');

    await show(tester);

    expect(find.text('Nothing on the map for Day 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Stop 1'), findsNothing);
  });

  testWidgets('OpenStreetMap is credited on the map', (tester) async {
    await show(tester);

    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('pinching never rotates the map; it stays north-up', (tester) async {
    await show(tester);

    final options = tester.widget<FlutterMap>(find.byType(FlutterMap)).options;
    expect(options.interactionOptions.flags & InteractiveFlag.rotate, 0);
    expect(options.minZoom, isNotNull);
  });

  testWidgets('the stop card sits above the nav bar and the phone\'s own button bar', (tester) async {
    await show(tester, systemBarHeight: 48);

    // The floating nav bar is 68 tall with a 16 margin, above the system bar.
    const navBarTop = 900 - 48 - 16 - 68;
    final card = tester.getRect(find.ancestor(of: find.text('Vidhana Soudha'), matching: find.byType(Container)).first);
    expect(card.bottom, lessThan(navBarTop));
  });

  testWidgets('the route line fits on one line', (tester) async {
    await show(tester);

    final line = find.textContaining(' km · ');
    expect(tester.getSize(line).height, lessThan(20));
  });
}
