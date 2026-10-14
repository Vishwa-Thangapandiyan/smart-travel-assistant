import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_data.dart';
import 'package:smart_travel_assistant/services/location_service.dart';
import 'package:smart_travel_assistant/services/offline_service.dart';
import 'package:smart_travel_assistant/services/overpass_service.dart';
import 'package:smart_travel_assistant/services/routing_service.dart';
import 'package:smart_travel_assistant/services/trip_service.dart';

void main() {
  group('in fake data mode', () {
    setUp(() {
      debugUseFakeData = true;
      resetFakeDownloads();
    });
    tearDown(() => debugUseFakeData = null);

    test('the demo user has the Bangalore trip, 20–23 Nov 2026', () async {
      final trips = await getTrips(demoUserId);

      expect(trips, hasLength(1));
      expect(trips.single.destination, 'Bangalore');
      expect(trips.single.startDate, DateTime(2026, 11, 20));
      expect(trips.single.endDate, DateTime(2026, 11, 23));
    });

    test('an unknown trip id gives null, not an error', () async {
      expect(await getTrip('no-such-trip'), isNull);
    });

    test('day 2 stops come back in the order the user put them', () async {
      final trip = (await getTrips(demoUserId)).single;
      final items = await getItineraryItems(trip.id);
      final day2 = items.where((i) => i.dayNumber == 2).map((i) => i.title).toList();

      expect(day2, [
        'MTR, Lalbagh Road',
        'Lalbagh Botanical Garden',
        'Bangalore Palace',
        'Cubbon Park',
        'Church Street',
      ]);
    });

    test('items are sorted by day first', () async {
      final trip = (await getTrips(demoUserId)).single;
      final days = (await getItineraryItems(trip.id)).map((i) => i.dayNumber).toList();

      expect(days, [...days]..sort());
    });

    test('a route runs from the origin to the destination', () async {
      // MTR to Bangalore Palace: about 4.89 km in a straight line,
      // worked out by hand from the coordinates (1° lat ≈ 111.2 km).
      final route = await getRoute(
        originLat: 12.95519,
        originLng: 77.58572,
        destLat: 12.99876,
        destLng: 77.59212,
      );

      expect(route.points.first.latitude, 12.95519);
      expect(route.points.last.latitude, 12.99876);
      expect(route.distanceMeters, closeTo(4890, 100));
      expect(route.durationSeconds, greaterThan(0));
    });

    test('nearby help includes hospitals, police, and an unnamed place', () async {
      final places = await findNearbyEmergencyServices(latitude: 12.9763, longitude: 77.5929);

      expect(places.map((p) => p.amenityType), containsAll(['hospital', 'police']));
      expect(places.any((p) => p.name == null || p.name!.isEmpty), isTrue);
    });

    test('there is a current position and an older saved one', () async {
      expect(await getCurrentPosition(), isNotNull);

      final saved = await getLastKnownLocation(demoUserId);
      expect(saved, isNotNull);
      expect(saved!.recordedAt.isBefore(DateTime.now()), isTrue);
    });

    test('a trip is only saved offline after it is downloaded', () async {
      final trip = (await getTrips(demoUserId)).single;

      expect(await isDownloaded(trip.id), isFalse);
      expect(await loadSavedTrip(trip.id), isNull);

      await downloadTrip(trip.id);

      expect(await isDownloaded(trip.id), isTrue);
      final saved = await loadSavedTrip(trip.id);
      expect(saved!.trip.destination, 'Bangalore');
      expect(saved.items, isNotEmpty);
    });
  });

  group('in real mode', () {
    setUp(() => debugUseFakeData = false);
    tearDown(() => debugUseFakeData = null);

    test('trip_service asks Supabase instead of returning the demo trip', () {
      // No Supabase in tests, so the real query fails — what matters is
      // that it is a real call, not the "not built yet" error.
      expect(getTrips(demoUserId), throwsA(isNot(isA<UnimplementedError>())));
    });
  });

  group('in real mode, a service nobody has built yet', () {
    setUp(() => debugUseFakeData = false);
    tearDown(() => debugUseFakeData = null);

    test('fails loudly instead of quietly returning fake data', () {
      expect(() => downloadTrip('t'), throwsA(isA<UnimplementedError>()));
    });
  });
}
