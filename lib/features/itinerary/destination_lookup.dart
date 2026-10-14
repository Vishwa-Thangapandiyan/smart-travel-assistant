// Owner: Vishwa. Turns a typed destination ("Bangalore") into coordinates
// with OpenStreetMap's Nominatim, once, when the user creates a trip.
//
// Nominatim's usage policy for the free server: at most one request a
// second, an identifying User-Agent, and no search-as-you-type. We call it
// once per tap on Create, so all three hold.

import 'dart:convert';

import 'package:http/http.dart' as http;

class DestinationMatch {
  final String name; // Nominatim's full name, shown so the user sees what matched
  final double latitude;
  final double longitude;

  const DestinationMatch({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

/// The shape of [lookUpDestination], so tests can pass a stand-in.
typedef LookUpDestination = Future<DestinationMatch?> Function(String destination);

/// Null when Nominatim finds nothing or can't be reached — the trip is
/// then saved without coordinates (they are nullable in `trips`).
Future<DestinationMatch?> lookUpDestination(String destination, {http.Client? client}) async {
  final url = Uri.https('nominatim.openstreetmap.org', '/search', {
    'q': destination,
    'format': 'json',
    'limit': '1',
  });
  final httpClient = client ?? http.Client();

  try {
    final response = await httpClient.get(url, headers: {
      'User-Agent': 'Meridian travel planner (VIT Chennai student project)',
    });
    if (response.statusCode != 200) return null;

    final results = jsonDecode(response.body) as List<dynamic>;
    if (results.isEmpty) return null;

    // Nominatim sends coordinates as strings.
    final first = results.first as Map<String, dynamic>;
    return DestinationMatch(
      name: first['display_name'] as String,
      latitude: double.parse(first['lat'] as String),
      longitude: double.parse(first['lon'] as String),
    );
  } on Exception {
    return null;
  } finally {
    if (client == null) httpClient.close();
  }
}
