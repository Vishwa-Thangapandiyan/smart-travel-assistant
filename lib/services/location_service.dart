// Owner: Vishwa (Maps). Called by Maps and Emergency; signature fixed in
// lib/services/README.md. The live position comes from geolocator, one
// lookup at a time (no background tracking — out of scope); the stored
// fallback lives in Supabase's last_known_location table. Staleness is
// the caller's decision, not this file's.

import 'package:geolocator/geolocator.dart';

import '../dev/app_config.dart';
import '../dev/fake_data.dart';
import '../models/last_known_location.dart';
import 'routing_service.dart';
import 'supabase_service.dart';

/// Null if location is switched off, permission is denied, or GPS gives
/// no fix within 15 seconds. Asks for permission the first time.
Future<RoutePoint?> getCurrentPosition() async {
  if (useFakeData) return RoutePoint(demoPosition.latitude, demoPosition.longitude);

  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return RoutePoint(position.latitude, position.longitude);
  } on Exception {
    return null;
  }
}

Future<LastKnownLocation?> getLastKnownLocation(String userId) async {
  if (useFakeData) return userId == demoUserId ? demoLastKnownLocation() : null;

  final row = await supabaseClient.from('last_known_location').select().eq('user_id', userId).maybeSingle();
  return row == null ? null : LastKnownLocation.fromJson(row);
}

/// One row per user (user_id is the primary key), so this overwrites the old one.
Future<void> saveLastKnownLocation({
  required String userId,
  required double latitude,
  required double longitude,
}) async {
  if (useFakeData) return; // fake mode keeps nothing

  await supabaseClient.from('last_known_location').upsert({
    'user_id': userId,
    'latitude': latitude,
    'longitude': longitude,
    'recorded_at': DateTime.now().toUtc().toIso8601String(),
  });
}
