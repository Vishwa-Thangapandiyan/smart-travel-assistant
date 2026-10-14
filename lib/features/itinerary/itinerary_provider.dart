// Owner: Vishwa. Holds the user's trips and the open trip's stops, so the
// Trips, Day and Map screens stay in sync — the TripProvider of
// lib/features/itinerary/README.md. Registered in lib/main.dart.
// Reads go through trip_service; writes happen here.

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../dev/app_config.dart';
import '../../dev/fake_data.dart';
import '../../models/itinerary_item.dart';
import '../../models/trip.dart';
import '../../services/supabase_service.dart';
import '../../services/trip_service.dart';
import 'destination_lookup.dart';
import 'trip_dates.dart';

class ItineraryProvider extends ChangeNotifier {
  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  Trip? _currentTrip;
  Trip? get currentTrip => _currentTrip;

  // The open trip's stops, sorted by day, then position.
  List<ItineraryItem> _stops = [];
  List<ItineraryItem> get stops => _stops;

  /// Forgets everything, for sign-out.
  void clear() {
    _trips = [];
    _currentTrip = null;
    _stops = [];
    notifyListeners();
  }

  Future<void> loadTrips(String userId) async {
    _trips = await getTrips(userId);
    notifyListeners();
  }

  /// [match] is the place the user picked from Nominatim, or null — the
  /// trip is then saved without coordinates.
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

  /// For the Map and Explore tabs: if the Trips tab hasn't opened a trip,
  /// open the next upcoming one (or the latest, if every trip is over).
  Future<void> openNextTripIfNone(String userId) async {
    if (_currentTrip != null) return;
    if (_trips.isEmpty) await loadTrips(userId);
    final trip = nextTrip(_trips, today: DateTime.now()) ?? _trips.lastOrNull;
    if (trip != null) await openTrip(trip);
  }

  Future<void> openTrip(Trip trip) async {
    _currentTrip = trip;
    _stops = await getItineraryItems(trip.id);
    notifyListeners();
  }

  /// One day's stops in the order the user put them.
  List<ItineraryItem> stopsForDay(int day) => _stops.where((s) => s.dayNumber == day).toList();

  /// Adds a stop at the end of [day] of the open trip.
  Future<void> addStop({
    required int day,
    required String title,
    String? locationName,
    double? latitude,
    double? longitude,
    String? startTime, // "HH:mm:ss"
    String? notes,
  }) async {
    final trip = _currentTrip!;
    final dayStops = stopsForDay(day);
    final position = dayStops.isEmpty ? 0 : dayStops.last.orderIndex + 1;

    final ItineraryItem stop;
    if (useFakeData) {
      stop = ItineraryItem(
        id: 'item-${DateTime.now().microsecondsSinceEpoch}',
        tripId: trip.id,
        dayNumber: day,
        title: title,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        startTime: startTime,
        orderIndex: position,
        notes: notes,
        createdAt: DateTime.now(),
      );
      fakeItems.add(stop);
    } else {
      final row = await supabaseClient
          .from('itinerary_items')
          .insert({
            'trip_id': trip.id,
            'day_number': day,
            'title': title,
            'location_name': locationName,
            'latitude': latitude,
            'longitude': longitude,
            'start_time': startTime,
            'order_index': position,
            'notes': notes,
          })
          .select()
          .single();
      stop = ItineraryItem.fromJson(row);
    }

    _stops = [..._stops, stop];
    _sortStops();
    notifyListeners();
  }

  /// Replaces every editable field of [stop] — pass the current value to keep one.
  Future<void> updateStop(
    ItineraryItem stop, {
    required String title,
    String? locationName,
    double? latitude,
    double? longitude,
    String? startTime,
    String? notes,
  }) async {
    final edited = ItineraryItem(
      id: stop.id,
      tripId: stop.tripId,
      dayNumber: stop.dayNumber,
      title: title,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      startTime: startTime,
      orderIndex: stop.orderIndex,
      notes: notes,
      createdAt: stop.createdAt,
    );
    await _save(edited);
    notifyListeners();
  }

  Future<void> deleteStop(ItineraryItem stop) async {
    if (useFakeData) {
      fakeItems.removeWhere((i) => i.id == stop.id);
    } else {
      await supabaseClient.from('itinerary_items').delete().eq('id', stop.id);
    }
    _stops = _stops.where((s) => s.id != stop.id).toList();
    notifyListeners();
  }

  /// Swaps [stop] with its neighbour above ([up]) or below in the same
  /// day, by swapping their order_index (REQ-2.3). Does nothing at either end.
  Future<void> moveStop(ItineraryItem stop, {required bool up}) async {
    final dayStops = stopsForDay(stop.dayNumber);
    final from = dayStops.indexWhere((s) => s.id == stop.id);
    final to = up ? from - 1 : from + 1;
    if (from == -1 || to < 0 || to >= dayStops.length) return;

    final neighbour = dayStops[to];
    await _save(_withPosition(stop, neighbour.orderIndex));
    await _save(_withPosition(neighbour, stop.orderIndex));
    _sortStops();
    notifyListeners();
  }

  ItineraryItem _withPosition(ItineraryItem stop, int orderIndex) {
    return ItineraryItem(
      id: stop.id,
      tripId: stop.tripId,
      dayNumber: stop.dayNumber,
      title: stop.title,
      locationName: stop.locationName,
      latitude: stop.latitude,
      longitude: stop.longitude,
      startTime: stop.startTime,
      orderIndex: orderIndex,
      notes: stop.notes,
      createdAt: stop.createdAt,
    );
  }

  // Writes one changed stop to storage and to the in-memory list.
  Future<void> _save(ItineraryItem stop) async {
    if (useFakeData) {
      final i = fakeItems.indexWhere((s) => s.id == stop.id);
      if (i != -1) fakeItems[i] = stop;
    } else {
      await supabaseClient.from('itinerary_items').update({
        'title': stop.title,
        'location_name': stop.locationName,
        'latitude': stop.latitude,
        'longitude': stop.longitude,
        'start_time': stop.startTime,
        'order_index': stop.orderIndex,
        'notes': stop.notes,
      }).eq('id', stop.id);
    }
    _stops = [for (final s in _stops) s.id == stop.id ? stop : s];
  }

  void _sortStops() {
    _stops.sort((a, b) {
      final byDay = a.dayNumber.compareTo(b.dayNumber);
      return byDay != 0 ? byDay : a.orderIndex.compareTo(b.orderIndex);
    });
  }
}
