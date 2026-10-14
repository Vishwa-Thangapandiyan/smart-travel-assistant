import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_data.dart';
import 'package:smart_travel_assistant/features/itinerary/destination_lookup.dart';
import 'package:smart_travel_assistant/features/itinerary/itinerary_provider.dart';
import 'package:smart_travel_assistant/features/itinerary/new_trip_check.dart';
import 'package:smart_travel_assistant/services/trip_service.dart';

void main() {
  group('the new-trip form check (Scene 3)', () {
    final nov20 = DateTime(2026, 11, 20);
    final nov23 = DateTime(2026, 11, 23);

    test('Bangalore, 20–23 Nov passes', () {
      final check = checkNewTrip(destination: 'Bangalore', start: nov20, end: nov23);

      expect(check.isValid, isTrue);
    });

    test('a one-day trip (same start and end) passes', () {
      expect(checkNewTrip(destination: 'Goa', start: nov20, end: nov20).isValid, isTrue);
    });

    test('an empty or blank destination is caught', () {
      final check = checkNewTrip(destination: '   ', start: nov20, end: nov23);

      expect(check.isValid, isFalse);
      expect(check.destination, isNotNull);
      expect(check.end, isNull);
    });

    test('an end date before the start date is caught on the end field', () {
      final check = checkNewTrip(destination: 'Bangalore', start: nov23, end: nov20);

      expect(check.isValid, isFalse);
      expect(check.end, isNotNull);
      expect(check.destination, isNull);
    });

    test('missing dates are caught on their own fields', () {
      final check = checkNewTrip(destination: 'Bangalore', start: null, end: null);

      expect(check.start, isNotNull);
      expect(check.end, isNotNull);
    });
  });

  group('creating a trip in fake data mode', () {
    setUp(() {
      debugUseFakeData = true;
      resetFakeTrips();
    });
    tearDown(() => debugUseFakeData = null);

    test('stores destination, dates and coordinates, and getTrips sees it', () async {
      final provider = ItineraryProvider();

      final trip = await provider.createTrip(
        userId: demoUserId,
        destination: '  Goa ',
        start: DateTime(2027, 1, 10),
        end: DateTime(2027, 1, 12),
        match: const DestinationMatch(name: 'Goa, India', latitude: 15.3, longitude: 74.08),
      );

      expect(trip.destination, 'Goa');
      expect(trip.startDate, DateTime(2027, 1, 10));
      expect(trip.endDate, DateTime(2027, 1, 12));
      expect(trip.latitude, 15.3);
      expect(trip.longitude, 74.08);
      expect(trip.numberOfDays, 3);
      expect((await getTrips(demoUserId)).map((t) => t.destination), contains('Goa'));
    });

    test('a destination Nominatim could not find is saved without coordinates', () async {
      final trip = await ItineraryProvider().createTrip(
        userId: demoUserId,
        destination: 'Somewhere',
        start: DateTime(2027, 1, 10),
        end: DateTime(2027, 1, 10),
        match: null,
      );

      expect(trip.latitude, isNull);
      expect(trip.longitude, isNull);
      expect(await getTrip(trip.id), isNotNull);
    });

    test('loadTrips fills the provider and tells listeners', () async {
      final provider = ItineraryProvider();
      var told = 0;
      provider.addListener(() => told++);

      await provider.loadTrips(demoUserId);

      expect(provider.trips.single.destination, 'Bangalore');
      expect(told, greaterThan(0));
    });
  });
}
