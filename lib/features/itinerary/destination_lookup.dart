// Owner: Vishwa. Turns a typed destination ("Bangalore") into up to three
// places with coordinates, using OpenStreetMap's Nominatim. The user picks
// one on the new-trip form.
//
// Nominatim's usage policy for the free server: at most one request a
// second, an identifying User-Agent, and no search-as-you-type. We search
// only when the user taps Search (or Create), so all three hold.

import 'dart:convert';

import 'package:http/http.dart' as http;

class DestinationMatch {
  final String name; // Nominatim's full name, shown so the user sees what matched
  final double latitude;
  final double longitude;

  /// "Bengaluru" from "Bengaluru, Bangalore North, Karnataka, India".
  String get placeName => name.split(',').first.trim();

  /// "Bangalore North, Karnataka, India" — the rest, to tell places apart.
  String get region {
    final comma = name.indexOf(',');
    return comma == -1 ? '' : name.substring(comma + 1).trim();
  }

  const DestinationMatch({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

/// The shape of [lookUpDestination], so tests can pass a stand-in.
typedef LookUpDestination = Future<List<DestinationMatch>> Function(String destination);

/// Best match first, at most three. Empty when Nominatim finds nothing or
/// can't be reached — the trip can still be saved without coordinates
/// (they are nullable in `trips`).
Future<List<DestinationMatch>> lookUpDestination(String destination, {http.Client? client}) async {
  final url = Uri.https('nominatim.openstreetmap.org', '/search', {
    'q': destination,
    'format': 'json',
    'limit': '3',
  });
  final httpClient = client ?? http.Client();

  try {
    final response = await httpClient.get(url, headers: {
      'User-Agent': 'Meridian travel planner (VIT Chennai student project)',
    });
    if (response.statusCode != 200) return [];

    final results = jsonDecode(response.body) as List<dynamic>;
    // Nominatim sends coordinates as strings.
    return [
      for (final place in results.cast<Map<String, dynamic>>())
        DestinationMatch(
          name: place['display_name'] as String,
          latitude: double.parse(place['lat'] as String),
          longitude: double.parse(place['lon'] as String),
        ),
    ];
  } on Exception {
    return [];
  } finally {
    if (client == null) httpClient.close();
  }
}
