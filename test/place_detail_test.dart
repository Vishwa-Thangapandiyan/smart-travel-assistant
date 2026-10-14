import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_data.dart';
import 'package:smart_travel_assistant/dev/fake_recommendations.dart';
import 'package:smart_travel_assistant/features/accounts/accounts_provider.dart';
import 'package:smart_travel_assistant/features/itinerary/itinerary_provider.dart';
import 'package:smart_travel_assistant/features/recommendations/place_detail_screen.dart';
import 'package:smart_travel_assistant/features/recommendations/place_photo.dart';
import 'package:smart_travel_assistant/features/recommendations/recommendations_provider.dart';
import 'package:smart_travel_assistant/features/recommendations/recommendations_screen.dart';
import 'package:smart_travel_assistant/theme/meridian_theme.dart';

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
  final lalbagh = fakeRecommendations.firstWhere((p) => p.name == 'Lalbagh Botanical Garden');
  final toit = fakeRecommendations.firstWhere((p) => p.name == 'Toit');

  setUp(() async {
    debugUseFakeData = true;
    resetFakeTrips();
    itinerary = ItineraryProvider();
    await itinerary.openNextTripIfNone(demoUserId);
  });
  tearDown(() => debugUseFakeData = null);

  Future<void> show(WidgetTester tester, Widget home) async {
    await tester.binding.setSurfaceSize(const Size(420, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(itinerary, home));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a card on Explore opens that place', (tester) async {
    await show(tester, const Scaffold(body: RecommendationsScreen()));

    await tester.tap(find.text('Cubbon Park'));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceDetailScreen), findsOneWidget);
    expect(find.text('Shaded park in the city centre with the State Central Library inside.'), findsOneWidget);
  });

  testWidgets('a place shows its city, facts, tags, map and photo credit', (tester) async {
    await show(tester, PlaceDetailScreen(place: lalbagh, showTiles: false));

    expect(find.text('BANGALORE'), findsOneWidget);
    expect(find.text('Lalbagh Botanical Garden'), findsOneWidget);
    expect(find.text('NATURE  ·  ★ 4.5  ·  ₹'), findsOneWidget);
    expect(find.text('glasshouse'), findsOneWidget);
    expect(find.text('WHERE IT IS'), findsOneWidget);
    expect(find.text('Photo: Wikimedia Commons'), findsOneWidget);
  });

  testWidgets('a place with no photo has no photo credit', (tester) async {
    await show(tester, PlaceDetailScreen(place: toit, showTiles: false));

    expect(find.text('Toit'), findsOneWidget);
    expect(find.text('Photo: Wikimedia Commons'), findsNothing);
  });

  testWidgets('Add to a day asks which day and marks the place as added', (tester) async {
    await show(tester, PlaceDetailScreen(place: lalbagh, showTiles: false));

    await tester.tap(find.text('Add to a day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day 1'));
    await tester.pumpAndSettle();

    expect(itinerary.stopsForDay(1).last.title, 'Lalbagh Botanical Garden');
    expect(find.text('On Fri 20 ✓'), findsOneWidget);
  });

  test('a photo URL leads to its Commons page, thumbnail or not', () {
    expect(
      photoSourcePage('https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d5/Cubbon_Park_W.jpg/960px-Cubbon_Park_W.jpg'),
      Uri.parse('https://commons.wikimedia.org/wiki/File:Cubbon_Park_W.jpg'),
    );
    expect(
      photoSourcePage('https://upload.wikimedia.org/wikipedia/commons/9/99/Kapaleeswarar1.jpg'),
      Uri.parse('https://commons.wikimedia.org/wiki/File:Kapaleeswarar1.jpg'),
    );
    expect(photoSourcePage('https://example.com/photo.jpg'), isNull);
  });

  test('every seeded photo is from Wikimedia Commons, so it has a credit page', () {
    final withPhotos = fakeRecommendations.where((p) => p.imageUrl != null).toList();

    expect(withPhotos, hasLength(54));
    for (final place in withPhotos) {
      expect(photoSourcePage(place.imageUrl!), isNotNull, reason: place.name);
    }
  });
}
