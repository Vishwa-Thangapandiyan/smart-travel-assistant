// Owner: Vishwa (Itinerary). Read-only access to trips for every other
// feature; signature fixed in lib/services/README.md. Writes stay in the
// Itinerary feature's provider. Throws on network failure — callers pick
// their own fallback.

import '../dev/app_config.dart';
import '../dev/fake_data.dart';
import '../models/itinerary_item.dart';
import '../models/trip.dart';
import 'supabase_service.dart';

Future<List<Trip>> getTrips(String userId) async {
  if (useFakeData) {
    return fakeTrips.where((t) => t.userId == userId).toList();
  }
  final rows = await supabaseClient
      .from('trips')
      .select()
      .eq('user_id', userId)
      .order('start_date');
  return rows.map(Trip.fromJson).toList();
}

/// Null if the trip doesn't exist.
Future<Trip?> getTrip(String tripId) async {
  if (useFakeData) {
    return fakeTrips.where((t) => t.id == tripId).firstOrNull;
  }
  final row = await supabaseClient.from('trips').select().eq('id', tripId).maybeSingle();
  return row == null ? null : Trip.fromJson(row);
}

/// Sorted by day_number, then order_index.
Future<List<ItineraryItem>> getItineraryItems(String tripId) async {
  if (useFakeData) {
    final items = demoItems.where((i) => i.tripId == tripId).toList();
    items.sort((a, b) {
      final byDay = a.dayNumber.compareTo(b.dayNumber);
      return byDay != 0 ? byDay : a.orderIndex.compareTo(b.orderIndex);
    });
    return items;
  }
  final rows = await supabaseClient
      .from('itinerary_items')
      .select()
      .eq('trip_id', tripId)
      .order('day_number')
      .order('order_index');
  return rows.map(ItineraryItem.fromJson).toList();
}
