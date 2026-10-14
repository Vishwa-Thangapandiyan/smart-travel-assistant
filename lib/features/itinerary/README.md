# Itinerary — REQ-2.1–2.4

Owner: Vishwa · Branch: `flex/itinerary` · SRS 4.2 · Record:
[`docs/OWNERSHIP.md`](../../../docs/OWNERSHIP.md)

**Design:** follow [`DESIGN.md`](../../../DESIGN.md); screen picture: `design/screens/night-02-trips.png`, `night-03-day.png`, `day-03-day.png`.

Create a trip, build a day-wise itinerary by hand, reorder stops. Maps,
Offline and Budget all read the `Trip` and `ItineraryItem` models this
feature writes, so their fields can't change — see
`lib/models/CONTRACT.md`. Other features read trips through
`lib/services/trip_service.dart` (signature in `lib/services/README.md`).

Nothing generates an itinerary. The user types each stop or taps a
recommendation. Don't build or imply anything else.

## Tasks

1. Build "create a trip": destination, start date, end date. Store the
   destination's coordinates (`Trip.latitude` / `.longitude`) at creation
   time — Maps needs them and the schema is frozen.
2. Build `lib/services/trip_service.dart` against its documented
   signature, replacing the fake version.
3. Build a `TripProvider` (`ChangeNotifier`) holding the current trip's
   itinerary items, so the itinerary and map screens stay in sync.
4. Plain CRUD first: add, edit and delete a stop for a given day. Get this
   fully working before touching reordering.
5. Reordering (REQ-2.3 says "reorder", not "drag"): up/down buttons that
   swap `order_index` between two adjacent items. `ReorderableListView`
   drag is an optional extra on top — it's part of the Flutter SDK, not a
   new dependency.
6. Notes per itinerary item.

## Done when

- [x] Creating a trip stores destination, dates and coordinates — REQ-2.1
- [x] Stops can be added, edited and deleted per day — REQ-2.2
- [x] Stops can be reordered within a day (arrow buttons at minimum) —
      REQ-2.3
- [x] Notes can be added to a stop — REQ-2.4
- [x] `trip_service.dart` is real and matches its documented signature
