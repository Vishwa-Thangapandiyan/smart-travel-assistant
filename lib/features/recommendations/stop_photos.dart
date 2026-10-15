// Owner: Vishwa. Photos for itinerary stops: a stop named like one of the
// places seeded for its trip's destination shows that place's photo. One
// query per trip. A stop typed by hand that matches no seeded place has
// no photo; nothing is searched for on the web.

import '../../dev/app_config.dart';
import '../../dev/fake_recommendations.dart';
import '../../models/itinerary_item.dart';
import '../../services/supabase_service.dart';
import 'recommendations_provider.dart' show seededDestination;

/// Lower-case place name → photo URL, for the places seeded for [destination].
Future<Map<String, String>> placePhotosFor(String destination) async {
  final seeded = seededDestination(destination);
  final List<({String name, String? imageUrl})> places;
  if (useFakeData) {
    places = [
      for (final place in fakeRecommendations)
        if (place.destination.toLowerCase() == seeded.toLowerCase()) (name: place.name, imageUrl: place.imageUrl),
    ];
  } else {
    final rows = await supabaseClient.from('recommendations').select('name, image_url').ilike('destination', seeded);
    places = [for (final row in rows) (name: row['name'] as String, imageUrl: row['image_url'] as String?)];
  }
  return {
    for (final place in places)
      if (place.imageUrl != null) place.name.toLowerCase(): place.imageUrl!,
  };
}

/// The photo for [stop]: matched on its title, or on the first part of its
/// place name ("Lalbagh Botanical Garden, Bengaluru" → "Lalbagh Botanical Garden").
String? photoForStop(ItineraryItem stop, Map<String, String> photos) {
  final byTitle = photos[stop.title.trim().toLowerCase()];
  if (byTitle != null) return byTitle;
  final place = stop.locationName?.split(',').first.trim().toLowerCase();
  return place == null ? null : photos[place];
}
