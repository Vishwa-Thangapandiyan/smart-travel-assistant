// Owner: Vishwa. Holds the user's trips (and, from issue #10, the current
// trip's itinerary) for the Days and Map screens — the TripProvider of
// lib/features/itinerary/README.md. Registered in lib/main.dart.
// Reads go through trip_service; writes happen here.

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../dev/app_config.dart';
import '../../dev/fake_data.dart';
import '../../models/trip.dart';
import '../../services/supabase_service.dart';
import '../../services/trip_service.dart';
import 'destination_lookup.dart';

class ItineraryProvider extends ChangeNotifier {
  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  Future<void> loadTrips(String userId) async {
    _trips = await getTrips(userId);
    notifyListeners();
  }

  /// [match] is the Nominatim result, or null if the lookup found nothing —
  /// the trip is then saved without coordinates.
  Future<Trip> createTrip({
    required String userId,
    required String destination,
    required DateTime start,
    required DateTime end,
    required DestinationMatch? match,
  }) async {
    final Trip trip;
    if (useFakeData) {
      trip = Trip(
        id: 'trip-${DateTime.now().microsecondsSinceEpoch}',
        userId: userId,
        destination: destination.trim(),
        startDate: start,
        endDate: end,
        latitude: match?.latitude,
        longitude: match?.longitude,
        createdAt: DateTime.now(),
      );
      fakeTrips.add(trip);
    } else {
      // Supabase fills in id and created_at and sends the saved row back.
      final dateOnly = DateFormat('yyyy-MM-dd');
      final row = await supabaseClient
          .from('trips')
          .insert({
            'user_id': userId,
            'destination': destination.trim(),
            'start_date': dateOnly.format(start),
            'end_date': dateOnly.format(end),
            'latitude': match?.latitude,
            'longitude': match?.longitude,
          })
          .select()
          .single();
      trip = Trip.fromJson(row);
    }

    _trips = [..._trips, trip]..sort((a, b) => a.startDate.compareTo(b.startDate));
    notifyListeners();
    return trip;
  }
}
