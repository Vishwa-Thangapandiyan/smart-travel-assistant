// Owner: Vishwa (Maps). Called by Maps and by Emergency's directions;
// signature fixed in lib/services/README.md. The real OSRM version
// arrives with issue #14.

import 'dart:math';

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

Future<RouteResult> getRoute({
  required double originLat,
  required double originLng,
  required double destLat,
  required double destLng,
}) async {
  if (!useFakeData) notBuiltYet('routing_service', 14);

  // Fake: a straight line at city driving speed. Good enough to draw and
  // to show a distance; the real route follows roads.
  const steps = 8;
  final points = [
    for (var i = 0; i <= steps; i++)
      RoutePoint(
        originLat + (destLat - originLat) * i / steps,
        originLng + (destLng - originLng) * i / steps,
      ),
  ];
  final meters = distanceBetween(originLat, originLng, destLat, destLng);
  const metersPerSecond = 25 * 1000 / 3600; // 25 km/h in city traffic
  return RouteResult(
    points: points,
    distanceMeters: meters,
    durationSeconds: meters / metersPerSecond,
  );
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
