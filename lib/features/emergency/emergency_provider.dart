// Owner: Sanjay. Everything the SOS screen shows: helplines (REQ-5.3),
// where the user is (live, or the saved fallback — REQ-5.4) and the
// hospitals and police near there (REQ-5.1). Registered in lib/main.dart.
//
// Order matters: helplines are there before anything loads and never
// depend on GPS or Overpass, because they must always be visible.

import 'package:flutter/foundation.dart';

import '../../dev/app_config.dart';
import '../../dev/fake_data.dart';
import '../../models/emergency_contact.dart';
import '../../services/location_service.dart';
import '../../services/overpass_service.dart';
import '../../services/routing_service.dart';
import '../../services/supabase_service.dart';

/// The national numbers from db/seed.sql, built into the app so they show
/// even when Supabase can't be reached (no signal, or not loaded yet).
const builtInHelplines = <EmergencyContact>[
  EmergencyContact(id: 'built-in-112', serviceName: 'Emergency', phoneNumber: '112', isDefault: true),
  EmergencyContact(id: 'built-in-100', serviceName: 'Police', phoneNumber: '100', isDefault: true),
  EmergencyContact(id: 'built-in-108', serviceName: 'Ambulance', phoneNumber: '108', isDefault: true),
  EmergencyContact(id: 'built-in-101', serviceName: 'Fire', phoneNumber: '101', isDefault: true),
];

/// A nearby place with its straight-line distance from the user.
class NearbyPlace {
  final OverpassPlace place;
  final double distanceMeters;
  const NearbyPlace(this.place, this.distanceMeters);
}

enum NearbyStatus { loading, loaded, failed, noLocation }

// The two lookups, swappable so tests can play "no GPS" or "Overpass is down".
typedef FindPosition = Future<RoutePoint?> Function();
typedef FindNearby = Future<List<OverpassPlace>> Function({required double latitude, required double longitude});

class EmergencyProvider extends ChangeNotifier {
  final FindPosition _currentPosition;
  final FindNearby _findNearbyPlaces;

  EmergencyProvider({
    FindPosition currentPosition = getCurrentPosition,
    FindNearby findNearby = findNearbyEmergencyServices,
  })  : _currentPosition = currentPosition,
        _findNearbyPlaces = findNearby;

  List<EmergencyContact> _helplines = builtInHelplines;
  List<EmergencyContact> get helplines => _helplines;

  RoutePoint? _position;
  RoutePoint? get position => _position;

  /// Set when the position is the saved fallback rather than live GPS.
  /// The screen must then say the location may be out of date (REQ-5.4).
  DateTime? _savedPositionTime;
  DateTime? get savedPositionTime => _savedPositionTime;
  bool get usingSavedPosition => _savedPositionTime != null;

  NearbyStatus _nearbyStatus = NearbyStatus.loading;
  NearbyStatus get nearbyStatus => _nearbyStatus;

  List<NearbyPlace> _nearby = [];
  List<NearbyPlace> get nearby => _nearby;

  /// Loads helplines, then position, then nearby places. Each step fails
  /// on its own without stopping the ones after it.
  Future<void> load(String? userId) async {
    _nearbyStatus = NearbyStatus.loading;
    notifyListeners();

    await _loadHelplines();
    await _findPosition(userId);
    await _findNearby();
  }

  Future<void> _loadHelplines() async {
    try {
      final List<EmergencyContact> loaded;
      if (useFakeData) {
        loaded = demoEmergencyContacts;
      } else {
        final rows = await supabaseClient.from('emergency_contacts').select().eq('is_default', true).order('phone_number');
        loaded = rows.map(EmergencyContact.fromJson).toList();
      }
      // An empty table would hide every number; keep the built-in ones then.
      if (loaded.isNotEmpty) _helplines = loaded;
    } catch (_) {
      // No signal or Supabase down: the built-in numbers stay on screen.
    }
    notifyListeners();
  }

  Future<void> _findPosition(String? userId) async {
    final live = await _currentPosition();
    if (live != null) {
      _position = live;
      _savedPositionTime = null;
      notifyListeners();
      if (userId != null) {
        try {
          await saveLastKnownLocation(userId: userId, latitude: live.latitude, longitude: live.longitude);
        } catch (_) {
          // Only kept for the next time GPS fails; not worth failing over.
        }
      }
      return;
    }

    // No live fix: fall back to the last saved position (REQ-5.4).
    try {
      final saved = userId == null ? null : await getLastKnownLocation(userId);
      if (saved != null) {
        _position = RoutePoint(saved.latitude, saved.longitude);
        _savedPositionTime = saved.recordedAt;
      }
    } catch (_) {
      // No signal for Supabase either — nothing to fall back to.
    }
    notifyListeners();
  }

  Future<void> _findNearby() async {
    final here = _position;
    if (here == null) {
      _nearbyStatus = NearbyStatus.noLocation;
      notifyListeners();
      return;
    }

    try {
      final places = await _findNearbyPlaces(latitude: here.latitude, longitude: here.longitude);
      _nearby = [
        for (final p in places)
          NearbyPlace(p, distanceBetween(here.latitude, here.longitude, p.latitude, p.longitude)),
      ]..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      _nearbyStatus = NearbyStatus.loaded;
    } catch (_) {
      // Slow, rate-limited or no signal. The helplines are still there.
      _nearby = [];
      _nearbyStatus = NearbyStatus.failed;
    }
    notifyListeners();
  }
}

/// "Hospital", "Police", or "Unnamed hospital" for an OSM entry with no name.
String placeTitle(OverpassPlace place) {
  final kind = place.amenityType == 'police' ? 'police station' : 'hospital';
  final name = place.name;
  return (name == null || name.isEmpty) ? 'Unnamed $kind' : name;
}

/// "1.2 km", or "450 m" when it's under a kilometre.
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// "12 min ago", "3 h ago", "2 days ago" — how old the saved position is.
String formatAge(DateTime recordedAt, DateTime now) {
  final age = now.difference(recordedAt);
  if (age.inMinutes < 1) return 'just now';
  if (age.inMinutes < 60) return '${age.inMinutes} min ago';
  if (age.inHours < 24) return '${age.inHours} h ago';
  final days = age.inDays;
  return days == 1 ? '1 day ago' : '$days days ago';
}
