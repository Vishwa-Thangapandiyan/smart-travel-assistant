// Owner: Vishwa (Itinerary). Read-only access to trips for every other
// feature; signature fixed in lib/services/README.md. The real version
// arrives with issue #9.

import '../dev/app_config.dart';
import '../dev/fake_data.dart';
import '../models/itinerary_item.dart';
import '../models/trip.dart';

Future<List<Trip>> getTrips(String userId) async {
  if (!useFakeData) notBuiltYet('trip_service', 9);
  return demoTrip.userId == userId ? [demoTrip] : [];
}

/// Null if the trip doesn't exist.
Future<Trip?> getTrip(String tripId) async {
  if (!useFakeData) notBuiltYet('trip_service', 9);
  return demoTrip.id == tripId ? demoTrip : null;
}

/// Sorted by day_number, then order_index.
Future<List<ItineraryItem>> getItineraryItems(String tripId) async {
  if (!useFakeData) notBuiltYet('trip_service', 9);
  final items = demoItems.where((i) => i.tripId == tripId).toList();
  items.sort((a, b) {
    final byDay = a.dayNumber.compareTo(b.dayNumber);
    return byDay != 0 ? byDay : a.orderIndex.compareTo(b.orderIndex);
  });
  return items;
}
