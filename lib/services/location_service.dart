// Owner: Vishwa (Maps). Called by Maps and Emergency; signature fixed in
// lib/services/README.md. The real geolocator + Supabase version arrives
// with issue #15. Staleness is the caller's decision, not this file's.

import '../dev/app_config.dart';
import '../dev/fake_data.dart';
import '../models/last_known_location.dart';
import 'routing_service.dart';

/// Null if permission is denied or GPS is unavailable.
Future<RoutePoint?> getCurrentPosition() async {
  if (!useFakeData) notBuiltYet('location_service', 15);
  return RoutePoint(demoPosition.latitude, demoPosition.longitude);
}

Future<LastKnownLocation?> getLastKnownLocation(String userId) async {
  if (!useFakeData) notBuiltYet('location_service', 15);
  return userId == demoUserId ? demoLastKnownLocation() : null;
}

Future<void> saveLastKnownLocation({
  required String userId,
  required double latitude,
  required double longitude,
}) async {
  if (!useFakeData) notBuiltYet('location_service', 15);
  // Fake mode keeps nothing; the real version writes last_known_location.
}
