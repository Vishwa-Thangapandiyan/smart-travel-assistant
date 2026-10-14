# lib/services/ — the service contract

This folder holds the Dart code that talks to anything outside the phone.
This README fixes the public signature of every service **before** it is
built, so anyone can call a service someone else owns without waiting
for their branch. Build against what's written here. If a signature needs
to change, tell the people who call it first — the same rule as
`lib/models/CONTRACT.md`.

None of these services hold state, do UI work, or know about Provider.
They take plain values in and return plain values (or `lib/models/`
classes) out.

## Fake data mode — why nobody waits

Vishwa's first PR (`flex/app-shell`) adds a fake version of every service
below, returning sample data from `lib/dev/fake_data.dart`: a signed-in
demo user, a demo trip with a few days of stops, a straight-line route,
and a couple of nearby hospitals and police stations.

- Run with `--dart-define=USE_FAKE_DATA=true` to use the fakes, or with no
  Supabase config at all — see `RUN.md`.
- Build your feature against the fakes from day one. When the real
  service merges, your code needs no change: the signature is the same.
- Each owner replaces the fake body of their own service with the real
  one. Never edit someone else's service to make your feature work.

| Service | Owner | Called by |
| --- | --- | --- |
| `supabase_service.dart` | Vishwa | everyone |
| `trip_service.dart` | Vishwa | Offline, Budget, Maps |
| `routing_service.dart` | Vishwa | Maps, Emergency |
| `location_service.dart` | Vishwa | Maps, Emergency |
| `offline_service.dart` | Sanjay | Offline |
| `overpass_service.dart` | Sanjay | Emergency |

---

## supabase_service.dart

Owner: Vishwa.

```dart
SupabaseClient get supabaseClient;
```

A single shared getter over `Supabase.instance.client`, initialised once
in `lib/main.dart`. Every other service and provider imports from here
instead of calling `Supabase.instance.client` directly.

---

## trip_service.dart

Owner: Vishwa (Itinerary). Read-only access to trips for every other
feature. Writes (create a trip, add/edit/reorder stops) stay inside the
Itinerary feature's `TripProvider`.

```dart
Future<List<Trip>> getTrips(String userId);

Future<Trip?> getTrip(String tripId);   // null if it doesn't exist

// Sorted by day_number, then order_index.
Future<List<ItineraryItem>> getItineraryItems(String tripId);
```

Throws on network failure — callers decide their own fallback (Offline
uses this to know it should show saved data).

---

## routing_service.dart

Owner: Vishwa. Called by Maps and by Emergency's directions (REQ-5.2).

```dart
class RoutePoint {
  final double latitude;
  final double longitude;
  const RoutePoint(this.latitude, this.longitude);
}

class RouteResult {
  final List<RoutePoint> points;   // the path, in order, for drawing on the map
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
});
```

Calls the public OSRM demo server. Throws on network failure, a
non-200 response, "no route" (`RouteException`) or no answer within 12
seconds — callers catch and show their own fallback (the map keeps its
pins with no line; Emergency shows distance without a route). Nothing is
cached; callers ask fresh every time.

Also, for a whole day of stops in one request (the Map screen uses it;
`getRoute` is this with two points):

```dart
Future<RouteResult> getRouteThrough(List<RoutePoint> stops);   // at least two stops, in order
```

---

## location_service.dart

Owner: Vishwa. Called by Maps and Emergency.

```dart
Future<RoutePoint?> getCurrentPosition();   // null if permission denied or GPS unavailable

Future<LastKnownLocation?> getLastKnownLocation(String userId);  // reads last_known_location via Supabase

Future<void> saveLastKnownLocation({
  required String userId,
  required double latitude,
  required double longitude,
});
```

Wraps `geolocator` for the live position and `supabase_service.dart` for
the stored fallback. Does not decide staleness — the caller compares
`LastKnownLocation.recordedAt` to `DateTime.now()` and decides whether to
flag it, per `lib/models/CONTRACT.md`.

---

## offline_service.dart

Owner: Sanjay (Offline, REQ-4.3).

```dart
class SavedTrip {
  final Trip trip;
  final List<ItineraryItem> items;
  final String? guideText;      // from the offline_packs row, if any
  final Uint8List? mapImage;    // the one static map image, if it downloaded
  final DateTime downloadedAt;
  const SavedTrip({
    required this.trip,
    required this.items,
    this.guideText,
    this.mapImage,
    required this.downloadedAt,
  });
}

Future<void> downloadTrip(String tripId);      // fetches via trip_service, writes Hive, records an OfflinePack row

Future<SavedTrip?> loadSavedTrip(String tripId);   // null if never downloaded

Future<bool> isDownloaded(String tripId);
```

Hive holds the payload; the `offline_packs` row in Supabase is only the
record that a download happened. Offline also provides two widgets other
screens place without editing: `DownloadTripButton(tripId)` and
`SavedTripScreen(tripId)` (see `lib/features/offline/README.md`).

---

## overpass_service.dart

Owner: Sanjay (Emergency).

```dart
class OverpassPlace {
  final String? name;   // null or empty if the OSM entry has no name tag
  final String amenityType;  // "hospital" or "police"
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
});
```

Queries Overpass for `amenity=hospital` and `amenity=police` within the
radius. Free and keyless. Can be slow, rate-limited or empty — callers
handle all three without crashing, and never depend on it to show the
default emergency numbers (those come from `emergency_contacts` via
`supabase_service.dart`).
