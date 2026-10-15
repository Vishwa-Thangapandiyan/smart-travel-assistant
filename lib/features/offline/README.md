# Offline access — REQ-4.3

Owner: Sanjay · Branch: `flex/offline` · SRS 4.4 · Record:
[`docs/OWNERSHIP.md`](../../../docs/OWNERSHIP.md)

**Design:** follow [`DESIGN.md`](../../../DESIGN.md); screen pictures: `design/screens/night-04-map-saved-offline.png` (saved-map state) and `night-03-day.png` (the "Saved offline" chip).

**Start after** Vishwa's app shell and theme are merged (`flex/app-shell`),
so the screens use the app's theme from the start.

Lets a user download a trip before leaving, then read it with no signal.
Builds `lib/services/offline_service.dart` (signature in
`lib/services/README.md`).

## Scope — be exact about this

A downloaded trip is: the trip row, all its itinerary items, the
destination's guide text, and **one static map image** per day (with
that day's route, issue #59). It is **not** a
pannable offline map, and the app must never describe it as "offline
maps". With no signal you can read the itinerary, guide and saved map
image, see budget numbers and call helplines — you cannot pan a live map,
get a new route, find nearby hospitals, or load recommendations.
See `PROJECT-UNDERSTANDING.md` Part 8.

Not decided by the team — don't build either way, flag it instead: what
happens if the user edits a trip while offline, and when a download
counts as stale.

## Where the guide text and the map image come from — decided (issue #24)

The `offline_packs` row has `guide_text` and `static_map_url`; this is
where they come from. No new table, no new package, no key.

- **Guide text** is a short note we wrote by hand for each of the five
  demo destinations — the same cities seeded in `recommendations`
  (Bangalore, Chennai, Goa, Jaipur, Mysore). It is bundled with the app in
  `destination_guides.dart` and copied into `guide_text` on download.
  Other names work the same way as Explore ("Bengaluru" → Bangalore). A
  trip anywhere else downloads without a guide, and the saved trip says so.
- **The static map image** — changed by issue #59: one picture per day
  that has a placed stop. `staticMapAreaFor` picks the closest zoom (16
  at most) at which all the day's stops and its route fit on a square
  two tiles across (512 px); the four to nine OpenStreetMap tiles under
  it are downloaded once each (days share tiles), with the app's
  User-Agent as OSM's tile policy asks, and stored as bytes in Hive,
  stopping at 900 KB so the copy stays under 1 MB. The route for each day
  comes from OSRM at download time (`getRouteThrough`), cut to about 300
  points and kept to five decimals. The saved trip lays the tiles side by
  side, draws the route and numbered stops on top, and shows the
  OpenStreetMap credit; `static_map_url` records an openstreetmap.org
  link to the first day's view. It is a picture: it does not pan or zoom,
  and the screen says so. If tiles fail to download, the stops and route
  still draw on a plain background.
- **Navigate** on each saved stop opens Google Maps directions to it
  (`lib/features/maps/navigate.dart`). Google Maps does the turn-by-turn;
  it works offline only where the person saved that area in Google Maps.

If the team wants a different source later (for example a guide row per
destination in Supabase), only `destination_guides.dart` and
`offline_service.dart` change.

## Tasks

1. Build `offline_service.dart`: fetch the trip and its items through
   `trip_service.dart` (use its fake data until the real one merges), plus
   guide text and one static map image, and write them into a Hive box
   with a timestamp.
2. Record each download as an `OfflinePack` row in Supabase (the record
   of what's downloaded; the payload itself lives in Hive).
3. Build `DownloadTripButton(tripId)` in this folder: a "Download for
   offline" action with a "Downloaded ✓" state. Vishwa's trip screen
   places it — you don't edit his screen.
4. Build `SavedTripScreen(tripId)` in this folder: a read-only view of the
   downloaded trip from Hive, under an "Offline — showing saved data"
   banner. The app opens it when Supabase can't be reached.
5. A trip that was never downloaded, opened offline, shows a clear message
   on `SavedTripScreen` — not a blank screen.
6. Test with the device or emulator in **Airplane Mode**, not just Wi-Fi
   off — some emulators keep a loopback connection alive and make the
   offline path look like it works when it wouldn't on a real phone.

## Done when

- [ ] A downloaded trip (itinerary + guide text + static map image) loads
      in Airplane Mode — REQ-4.3 (built and read from Hive only; still to
      check on a phone in Airplane Mode, with the per-day maps and routes
      from issue #59)
- [x] An `OfflinePack` row is written on download
- [x] The offline banner shows whenever saved data is being displayed
- [x] A never-downloaded trip opened offline shows a clear message
