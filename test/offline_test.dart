import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_data.dart';
import 'package:smart_travel_assistant/features/offline/destination_guides.dart';
import 'package:smart_travel_assistant/features/offline/download_trip_button.dart';
import 'package:smart_travel_assistant/features/offline/offline_provider.dart';
import 'package:smart_travel_assistant/features/offline/saved_trip_screen.dart';
import 'package:smart_travel_assistant/models/trip.dart';
import 'package:smart_travel_assistant/services/offline_service.dart';
import 'package:smart_travel_assistant/theme/meridian_theme.dart';

void main() {
  group('where the guide and map come from (issue #24)', () {
    test('the five demo cities have a guide, under their other names too', () {
      for (final city in ['Bangalore', 'Bengaluru', 'Chennai', 'Goa', 'Jaipur', 'Mysuru']) {
        expect(guideFor(city), isNotNull, reason: city);
      }
      expect(guideFor('Paris'), isNull);
    });

    test('the map is the one zoom-12 OpenStreetMap tile holding the trip centre', () {
      final tile = staticMapTileFor(demoTrip, demoItems)!;

      expect(tile.url, matches(RegExp(r'^https://tile\.openstreetmap\.org/12/\d+/\d+\.png$')));
      expect(tile.positionOf(demoTrip.latitude!, demoTrip.longitude!), isNotNull);
      // Mysore is about 125 km away — well off a 10 km tile.
      expect(tile.positionOf(12.30522, 76.65538), isNull);
    });

    test('a trip with no coordinates centres on its first placed stop, or has no map', () {
      final noCentre = Trip(
        id: 't',
        userId: demoUserId,
        destination: 'Somewhere',
        startDate: DateTime(2026, 11, 20),
        endDate: DateTime(2026, 11, 21),
        createdAt: DateTime(2026, 10, 14),
      );

      final tile = staticMapTileFor(noCentre, demoItems)!;
      expect(tile.positionOf(demoItems.first.latitude!, demoItems.first.longitude!), isNotNull);
      expect(staticMapTileFor(noCentre, []), isNull);
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
      expect(saved.mapImage, isNull); // no internet in fake mode
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

    test('reads back exactly what was written, map image included', () async {
      final downloadedAt = DateTime(2026, 11, 19, 21, 30);
      await storeSavedTrip(SavedTrip(
        trip: demoTrip,
        items: demoItems,
        guideText: guideFor('Bangalore'),
        mapImage: utf8.encode('saved map'),
        downloadedAt: downloadedAt,
      ));

      expect(await isDownloaded(demoTrip.id), isTrue);
      final saved = (await loadSavedTrip(demoTrip.id))!;
      expect(saved.trip.destination, 'Bangalore');
      expect(saved.trip.startDate, DateTime(2026, 11, 20));
      expect(saved.items.map((i) => i.title), demoItems.map((i) => i.title));
      expect(saved.items[1].notes, 'Dinner');
      expect(saved.guideText, guideFor('Bangalore'));
      expect(saved.mapImage, utf8.encode('saved map'));
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
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await downloadTrip(demoTrip.id);

      await tester.pumpWidget(app(SavedTripScreen(tripId: demoTrip.id)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Offline — showing saved data'), findsOneWidget);
      expect(find.text('Bangalore'), findsOneWidget);
      expect(find.text(guideFor('Bangalore')!), findsOneWidget);
      expect(find.text('Vidhana Soudha'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('No map image was saved with this trip.'), findsOneWidget);
    });
  });
}
