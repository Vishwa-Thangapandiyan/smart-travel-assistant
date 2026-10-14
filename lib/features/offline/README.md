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
destination's guide text, and **one static map image**. It is **not** a
pannable offline map, and the app must never describe it as "offline
maps". With no signal you can read the itinerary, guide and saved map
image, see budget numbers and call helplines — you cannot pan a live map,
get a new route, find nearby hospitals, or load recommendations.
See `PROJECT-UNDERSTANDING.md` Part 8.

Not decided by the team — don't build either way, flag it instead: what
happens if the user edits a trip while offline, and when a download
counts as stale.

**Open question, ask before building task 1:** the `offline_packs` row has
`guide_text` and `static_map_url` columns, but nothing in the docs says
where a destination's guide text or static map image comes from in the
first place. Agree the source with the team (for example, seeded per demo
destination) instead of inventing one.

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
      in Airplane Mode — REQ-4.3
- [ ] An `OfflinePack` row is written on download
- [ ] The offline banner shows whenever saved data is being displayed
- [ ] A never-downloaded trip opened offline shows a clear message
