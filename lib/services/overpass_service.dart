// Owner: Sanjay (Emergency, REQ-5.1). Signature fixed in
// lib/services/README.md. Asks the public Overpass API for hospitals and
// police near a point. Overpass is a search over OpenStreetMap data, not
// an emergency service: entries can be missing, old or unnamed, and the
// server can be slow or rate-limited. This throws on any of those, and the
// caller shows the helplines regardless.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../dev/app_config.dart';

class OverpassPlace {
  final String? name; // null or empty if the OSM entry has no name tag
  final String amenityType; // "hospital" or "police"
  final double latitude;
  final double longitude;
  final String? phone; // the OSM phone tag, if anyone added one
  const OverpassPlace({
    this.name,
    required this.amenityType,
    required this.latitude,
    required this.longitude,
    this.phone,
  });
}

/// Overpass answered, but not with places (busy, rate-limited, or an error).
class OverpassException implements Exception {
  final String message;
  const OverpassException(this.message);

  @override
  String toString() => 'OverpassException: $message';
}

Future<List<OverpassPlace>> findNearbyEmergencyServices({
  required double latitude,
  required double longitude,
  double radiusMeters = 5000,
  http.Client? client,
}) async {
  if (useFakeData) {
    // Real places near Cubbon Park, plus one with no name — Overpass
    // returns those too, and the panel has to handle them.
    return const [
      OverpassPlace(name: 'Bowring and Lady Curzon Hospital', amenityType: 'hospital', latitude: 12.9824, longitude: 77.6065),
      OverpassPlace(name: 'Cubbon Park Police Station', amenityType: 'police', latitude: 12.9775, longitude: 77.5966),
      OverpassPlace(name: "St. Martha's Hospital", amenityType: 'hospital', latitude: 12.9667, longitude: 77.5878),
      OverpassPlace(amenityType: 'hospital', latitude: 12.9590, longitude: 77.6010),
    ];
  }

  // Nodes have a position; buildings (ways) and sites (relations) get
  // their centre from "out center".
  final radius = radiusMeters.round();
  final query = '[out:json][timeout:15];'
      '('
      'nwr["amenity"="hospital"](around:$radius,$latitude,$longitude);'
      'nwr["amenity"="police"](around:$radius,$latitude,$longitude);'
      ');'
      'out center tags;';
  final httpClient = client ?? http.Client();

  try {
    final response = await httpClient.post(
      Uri.https('overpass-api.de', '/api/interpreter'),
      headers: {'User-Agent': 'Meridian travel planner (VIT Chennai student project)'},
      body: {'data': query},
    ).timeout(const Duration(seconds: 20));
    // 429 means rate-limited, 504 means the server is too busy.
    if (response.statusCode != 200) {
      throw OverpassException('Overpass answered ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = body['elements'] as List<dynamic>? ?? [];
    final places = <OverpassPlace>[];
    for (final element in elements.cast<Map<String, dynamic>>()) {
      final place = _placeFrom(element);
      if (place != null) places.add(place);
    }
    return places;
  } finally {
    if (client == null) httpClient.close();
  }
}

// Null for an entry with no usable position or an unexpected amenity.
OverpassPlace? _placeFrom(Map<String, dynamic> element) {
  final tags = element['tags'] as Map<String, dynamic>? ?? {};
  final amenity = tags['amenity'];
  if (amenity != 'hospital' && amenity != 'police') return null;

  final centre = element['center'] as Map<String, dynamic>?;
  final lat = (element['lat'] ?? centre?['lat']) as num?;
  final lon = (element['lon'] ?? centre?['lon']) as num?;
  if (lat == null || lon == null) return null;

  final name = (tags['name:en'] ?? tags['name']) as String?;
  final phone = (tags['phone'] ?? tags['contact:phone']) as String?;
  return OverpassPlace(
    name: (name == null || name.trim().isEmpty) ? null : name.trim(),
    amenityType: amenity as String,
    latitude: lat.toDouble(),
    longitude: lon.toDouble(),
    // Some entries list several numbers separated by ";" — keep the first.
    phone: phone?.split(';').first.trim(),
  );
}
