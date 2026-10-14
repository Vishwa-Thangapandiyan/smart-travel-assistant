// Owner: Vishwa (Maps). Called by Maps and by Emergency's directions;
// signature fixed in lib/services/README.md. Asks the public OSRM demo
// server for the road route. Throws on failure or a slow answer — callers
// keep their pins and show no line. Nothing is cached.

import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../dev/app_config.dart';

class RoutePoint {
  final double latitude;
  final double longitude;
  const RoutePoint(this.latitude, this.longitude);
}

class RouteResult {
  final List<RoutePoint> points; // the path, in order, for drawing on the map
  final double distanceMeters;
  final double durationSeconds;
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

/// OSRM answered, but not with a route (error status, or no road found).
class RouteException implements Exception {
  final String message;
  const RouteException(this.message);

  @override
  String toString() => 'RouteException: $message';
}

Future<RouteResult> getRoute({
  required double originLat,
  required double originLng,
  required double destLat,
  required double destLng,
}) {
  return getRouteThrough([RoutePoint(originLat, originLng), RoutePoint(destLat, destLng)]);
}

/// The road route through every stop in order, in one OSRM request — the
/// Map screen uses this for a whole day. Needs at least two stops.
Future<RouteResult> getRouteThrough(List<RoutePoint> stops, {http.Client? client}) async {
  if (stops.length < 2) throw ArgumentError('A route needs at least two stops.');
  if (useFakeData) return _straightLines(stops);

  // OSRM wants "longitude,latitude" pairs joined by semicolons.
  final path = stops.map((s) => '${s.longitude},${s.latitude}').join(';');
  final url = Uri.https('router.project-osrm.org', '/route/v1/driving/$path', {
    'overview': 'full',
    'geometries': 'geojson',
  });
  final httpClient = client ?? http.Client();

  try {
    final response = await httpClient.get(url, headers: {
      'User-Agent': 'Meridian travel planner (VIT Chennai student project)',
    }).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw RouteException('OSRM answered ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = body['routes'] as List<dynamic>? ?? [];
    if (body['code'] != 'Ok' || routes.isEmpty) {
      throw RouteException('OSRM found no route (${body['code']})');
    }

    final route = routes.first as Map<String, dynamic>;
    final coordinates = (route['geometry'] as Map<String, dynamic>)['coordinates'] as List<dynamic>;
    return RouteResult(
      // GeoJSON is [longitude, latitude]; flip each pair.
      points: [
        for (final pair in coordinates.cast<List<dynamic>>())
          RoutePoint((pair[1] as num).toDouble(), (pair[0] as num).toDouble()),
      ],
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  } finally {
    if (client == null) httpClient.close();
  }
}

// Fake data mode: straight lines between the stops at city driving speed.
// Good enough to draw and to show a distance; the real route follows roads.
RouteResult _straightLines(List<RoutePoint> stops) {
  final points = <RoutePoint>[stops.first];
  var meters = 0.0;
  for (var i = 1; i < stops.length; i++) {
    final from = stops[i - 1];
    final to = stops[i];
    const steps = 8;
    for (var step = 1; step <= steps; step++) {
      points.add(RoutePoint(
        from.latitude + (to.latitude - from.latitude) * step / steps,
        from.longitude + (to.longitude - from.longitude) * step / steps,
      ));
    }
    meters += distanceBetween(from.latitude, from.longitude, to.latitude, to.longitude);
  }
  const metersPerSecond = 25 * 1000 / 3600; // 25 km/h in city traffic
  return RouteResult(points: points, distanceMeters: meters, durationSeconds: meters / metersPerSecond);
}

/// Straight-line distance in metres (haversine formula).
double distanceBetween(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  double rad(double degrees) => degrees * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
}
