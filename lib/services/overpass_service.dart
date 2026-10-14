// Owner: Sanjay (Emergency). Signature fixed in lib/services/README.md.
// The real Overpass version arrives with issue #19. Callers must cope
// with slow, empty and unnamed results.

import '../dev/app_config.dart';

class OverpassPlace {
  final String? name; // null or empty if the OSM entry has no name tag
  final String amenityType; // "hospital" or "police"
  final double latitude;
  final double longitude;
  const OverpassPlace({
    this.name,
    required this.amenityType,
    required this.latitude,
    required this.longitude,
  });
}

Future<List<OverpassPlace>> findNearbyEmergencyServices({
  required double latitude,
  required double longitude,
  double radiusMeters = 5000,
}) async {
  if (!useFakeData) notBuiltYet('overpass_service', 19);
  // Real places near Cubbon Park, plus one with no name — Overpass
  // returns those too, and the panel has to handle them.
  return const [
    OverpassPlace(name: 'Bowring and Lady Curzon Hospital', amenityType: 'hospital', latitude: 12.9824, longitude: 77.6065),
    OverpassPlace(name: 'Cubbon Park Police Station', amenityType: 'police', latitude: 12.9775, longitude: 77.5966),
    OverpassPlace(name: "St. Martha's Hospital", amenityType: 'hospital', latitude: 12.9667, longitude: 77.5878),
    OverpassPlace(amenityType: 'hospital', latitude: 12.9590, longitude: 77.6010),
  ];
}
