# Maps & routing — REQ-4.1, 4.2

Owner: Vishwa · Branch: `flex/maps` · SRS 4.4 · Record:
[`docs/OWNERSHIP.md`](../../../docs/OWNERSHIP.md)

**Design:** follow [`DESIGN.md`](../../../DESIGN.md); screen picture: `design/screens/night-04-map-saved-offline.png`, `day-04-map.png`.

Plots a trip's stops on an OpenStreetMap map and draws a road route
between them. Offline access (REQ-4.3) is a separate feature owned by
Sanjay — see `lib/features/offline/README.md`.

Builds `lib/services/routing_service.dart` and
`lib/services/location_service.dart`. Emergency (Sanjay) calls both, so
**never change their signatures** in `lib/services/README.md` without
telling Sanjay first.

## Tasks

1. Set up `flutter_map` with an OpenStreetMap tile layer. Add the
   `INTERNET` permission to `android/app/src/main/AndroidManifest.xml` —
   without it the map stays blank with no error.
2. Show OSM attribution on the map (`RichAttributionWidget` or
   equivalent). This is a licence condition, not a style choice.
3. Plot itinerary stops as markers from `ItineraryItem.latitude` /
   `.longitude`.
4. Build `routing_service.dart` as a plain function calling the public
   OSRM server, matching the documented signature and replacing the fake.
5. Build `location_service.dart` (geolocator for the live position,
   Supabase for the stored last-known position), and add the
   `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` permissions.
6. Handle a slow or unreachable OSRM server: time out, keep the pins, show
   no line rather than spinning for ever.

## Done when

- [x] Map renders with visible tiles and correct markers — REQ-4.1
- [x] OSM attribution is visible — REQ-4.1
- [x] Routing between stops works via OSRM through
      `routing_service.dart` — REQ-4.2
- [x] `location_service.dart` is real and matches its signature
- [x] A map with zero stops shows a sensible empty state, no crash
