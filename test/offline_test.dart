import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_data.dart';
import 'package:smart_travel_assistant/features/offline/destination_guides.dart';
import 'package:smart_travel_assistant/features/offline/download_trip_button.dart';
import 'package:smart_travel_assistant/features/offline/offline_provider.dart';
import 'package:smart_travel_assistant/features/maps/navigate.dart';
import 'package:smart_travel_assistant/features/offline/saved_trip_screen.dart';
import 'package:smart_travel_assistant/services/offline_service.dart';
import 'package:smart_travel_assistant/services/routing_service.dart';
import 'package:smart_travel_assistant/theme/meridian_theme.dart';

void main() {
  group('where the guide comes from (issue #24)', () {
    test('the five demo cities have a guide, under their other names too', () {
      for (final city in ['Bangalore', 'Bengaluru', 'Chennai', 'Goa', 'Jaipur', 'Mysuru']) {
        expect(guideFor(city), isNotNull, reason: city);
      }
      expect(guideFor('Paris'), isNull);
    });
  });

  group('the saved map (issue #59)', () {
    test('each day with a placed stop gets its own map, and every stop is on it', () {
      final areas = dayMapAreas(demoTrip, demoItems, {});

      expect(areas.keys, [1, 2, 3, 4]);
      for (final stop in demoItems) {
        expect(areas[stop.dayNumber]!.positionOf(stop.latitude!, stop.longitude!), isNotNull, reason: stop.title);
      }
      // The airport is 30 km out, but only on Day 4: Day 2 stays a city map.
      expect(areas[2]!.zoom, greaterThanOrEqualTo(13));
      expect(areas[4]!.zoom, 16);
      expect(areas[2]!.positionOf(13.1986, 77.7066), isNull);
    });

    test('the route counts too, so a detour is not cut off', () {
      final detour = [const RoutePoint(12.9796, 77.5907), const RoutePoint(13.05, 77.62), const RoutePoint(12.9452, 77.5713)];
      final area = dayMapAreas(demoTrip, demoItems, {1: detour})[1]!;

      expect(area.positionOf(13.05, 77.62), isNotNull);
    });

    test('the tiles cover the whole picture, with no gap at the edges', () {
      final area = staticMapAreaFor([const RoutePoint(12.9716, 77.5946)])!;
      final tiles = area.tiles;

      expect(tiles.length, inInclusiveRange(4, 9));
      for (final tile in tiles) {
        expect(tile.url, matches(RegExp(r'^https://tile\.openstreetmap\.org/16/\d+/\d+\.png$')));
      }
      expect(tiles.map((t) => t.across).reduce(min), lessThanOrEqualTo(0));
      expect(tiles.map((t) => t.down).reduce(min), lessThanOrEqualTo(0));
      expect(tiles.map((t) => t.across + 1 / StaticMapArea.size).reduce(max), greaterThanOrEqualTo(1));
      expect(tiles.map((t) => t.down + 1 / StaticMapArea.size).reduce(max), greaterThanOrEqualTo(1));
    });

    test('no placed stops means no map', () {
      expect(staticMapAreaFor([]), isNull);
    });

    test('Navigate opens Google Maps directions to the stop', () {
      expect(
        directionsTo(12.9796, 77.5907).toString(),
        'https://www.google.com/maps/dir/?api=1&destination=12.9796,77.5907',
      );
    });
  });

  group('downloading in fake data mode', () {
    setUp(() async {
      debugUseFakeData = true;
      resetFakeTrips();
      await resetFakeDownloads();
    });
    tearDown(() => debugUseFakeData = null);

    test('the saved copy has the trip, its stops and the guide', () async {
      await downloadTrip(demoTrip.id);
      final saved = (await loadSavedTrip(demoTrip.id))!;

      expect(saved.trip.destination, 'Bangalore');
      expect(saved.items, hasLength(demoItems.length));
      expect(saved.guideText, guideFor('Bangalore'));
      expect(saved.mapTiles, isEmpty); // no internet in fake mode
      expect(saved.mapAreas.keys, [1, 2, 3, 4]);
      // Day 4 has one stop, so no route; the others have their demo lines.
      expect(saved.routes.keys, unorderedEquals([1, 2, 3]));
      expect(saved.routes[2]!.first.latitude, 12.95519);
    });

    test('a trip that does not exist fails instead of looking downloaded', () async {
      await expectLater(downloadTrip('no-such-trip'), throwsA(isA<StateError>()));
      expect(await isDownloaded('no-such-trip'), isFalse);
    });

    test('OfflineProvider tracks the download, and a failed one is not marked done', () async {
      final offline = OfflineProvider();

      expect(await offline.download(demoTrip.id), isTrue);
      expect(offline.isDownloaded(demoTrip.id), isTrue);
      expect(offline.isDownloading(demoTrip.id), isFalse);

      expect(await offline.download('no-such-trip'), isFalse);
      expect(offline.isDownloaded('no-such-trip'), isFalse);
    });
  });

  group('the copy in Hive', () {
    late Directory folder;

    setUpAll(() {
      folder = Directory.systemTemp.createTempSync('meridian_hive_test');
      useHiveFolderForTests(folder.path);
    });
    setUp(() async {
      debugUseFakeData = false;
      await resetFakeDownloads();
    });
    tearDown(() => debugUseFakeData = null);
    tearDownAll(() async {
      await Hive.close();
      folder.deleteSync(recursive: true);
    });

    test('reads back exactly what was written, map and route included', () async {
      final downloadedAt = DateTime(2026, 11, 19, 21, 30);
      const area = StaticMapArea(zoom: 14, latitude: 12.96, longitude: 77.58);
      await storeSavedTrip(SavedTrip(
        trip: demoTrip,
        items: demoItems,
        guideText: guideFor('Bangalore'),
        mapAreas: {2: area},
        mapTiles: {area.tiles.first.url: utf8.encode('saved tile')},
        routes: {2: [const RoutePoint(12.955191234, 77.585721234), const RoutePoint(12.95073, 77.58483)]},
        downloadedAt: downloadedAt,
      ));

      expect(await isDownloaded(demoTrip.id), isTrue);
      final saved = (await loadSavedTrip(demoTrip.id))!;
      expect(saved.trip.destination, 'Bangalore');
      expect(saved.trip.startDate, DateTime(2026, 11, 20));
      expect(saved.items.map((i) => i.title), demoItems.map((i) => i.title));
      expect(saved.items[1].notes, 'Dinner');
      expect(saved.guideText, guideFor('Bangalore'));
      expect(saved.mapAreas[2]!.zoom, 14);
      expect(saved.mapAreas[2]!.latitude, 12.96);
      expect(saved.mapTiles[area.tiles.first.url], utf8.encode('saved tile'));
      // Kept to five decimals, about a metre.
      expect(saved.routes[2]!.first.latitude, 12.95519);
      expect(saved.routes[2]!.first.longitude, 77.58572);
      expect(saved.routes[2], hasLength(2));
      expect(saved.downloadedAt, downloadedAt);
    });

    test('a trip never downloaded is not there', () async {
      expect(await isDownloaded('never-downloaded'), isFalse);
      expect(await loadSavedTrip('never-downloaded'), isNull);
    });
  });

  group('screens', () {
    setUp(() async {
      debugUseFakeData = true;
      resetFakeTrips();
      await resetFakeDownloads();
    });
    tearDown(() => debugUseFakeData = null);

    Widget app(Widget home) => ChangeNotifierProvider(
          create: (_) => OfflineProvider(),
          child: MaterialApp(theme: meridianTheme(Brightness.dark), home: home),
        );

    testWidgets('the button downloads the trip and then says so', (tester) async {
      await tester.pumpWidget(app(Scaffold(body: Center(child: DownloadTripButton(tripId: demoTrip.id)))));
      await tester.pumpAndSettle();
      expect(find.text('Download for offline'), findsOneWidget);

      await tester.tap(find.text('Download for offline'));
      await tester.pumpAndSettle();

      expect(find.text('Downloaded ✓'), findsOneWidget);
      expect(await isDownloaded(demoTrip.id), isTrue);
    });

    testWidgets('a trip downloaded earlier shows as downloaded straight away', (tester) async {
      await downloadTrip(demoTrip.id);

      await tester.pumpWidget(app(Scaffold(body: Center(child: DownloadTripButton(tripId: demoTrip.id)))));
      await tester.pumpAndSettle();

      expect(find.text('Downloaded ✓'), findsOneWidget);
    });

    testWidgets('a never-downloaded trip gets a clear message, not a blank screen', (tester) async {
      await tester.pumpWidget(app(SavedTripScreen(tripId: demoTrip.id)));
      await tester.pumpAndSettle();

      expect(find.text("This trip isn't saved on this phone"), findsOneWidget);
    });

    testWidgets('a downloaded trip shows under the offline banner', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 3200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await downloadTrip(demoTrip.id);

      await tester.pumpWidget(app(SavedTripScreen(tripId: demoTrip.id)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Offline — showing saved data'), findsOneWidget);
      expect(find.text('Bangalore'), findsOneWidget);
      expect(find.text(guideFor('Bangalore')!), findsOneWidget);
      expect(find.text('Vidhana Soudha'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      // Fake mode has no internet: the stops and route draw on a plain background.
      expect(find.text("The map tiles didn't download, so this shows the stops and route only."), findsOneWidget);
      expect(find.byTooltip('Navigate'), findsNWidgets(demoItems.length));
    });

    testWidgets('the Day chips switch the saved map between days', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 3200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await downloadTrip(demoTrip.id);

      await tester.pumpWidget(app(SavedTripScreen(tripId: demoTrip.id)));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('^Saved map of Bangalore, day 1')), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Day 2'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('^Saved map of Bangalore, day 2')), findsOneWidget);
    });
  });
}
