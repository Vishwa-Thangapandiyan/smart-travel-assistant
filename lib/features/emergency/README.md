# Emergency assistance — REQ-5.1–5.4

Owner: Sanjay · Branch: `flex/emergency` · SRS 4.5 · Record:
[`docs/OWNERSHIP.md`](../../../docs/OWNERSHIP.md)

**Start after** Vishwa's app shell and theme are merged (`flex/app-shell`).

Nearby hospitals and police stations, default helpline numbers with
one-tap calling, directions to the nearest service, and a last-known
location fallback. Builds `lib/services/overpass_service.dart`; calls
Vishwa's `routing_service.dart` and `location_service.dart` through their
documented signatures (fake data until the real ones merge — never wait).

## Tasks

1. Build `overpass_service.dart`: query Overpass for `amenity=hospital`
   and `amenity=police` near the user's position. Free and keyless — see
   `lib/services/README.md` for the signature.
2. Handle slow or rate-limited Overpass responses, and OSM entries with no
   name — neither may crash the panel or show a blank entry.
3. Keep the default helplines (112, 100, 108, 101, plus those in
   `db/seed.sql`) visible at all times, even when Overpass returns nothing.
   They come from `EmergencyContact` rows via Supabase, not from Overpass.
4. One-tap calling with `url_launcher`:
   `launchUrl(Uri(scheme: 'tel', path: phoneNumber))`. No other telephony
   package.
5. Directions to the nearest service (REQ-5.2): call
   `routing_service.dart`'s `getRoute(...)` with the user's position and
   the chosen place. If routing fails, show the distance without a line.
6. The safety disclaimer, **required by SRS section 5.2**: the panel must
   say this is not a certified emergency-dispatch system and that in a
   life-threatening emergency the user should also call local services
   directly. (A different "5.2" from REQ-5.2 — don't confuse them.)
7. Last-known-location fallback (REQ-5.4), both parts: use the saved
   `LastKnownLocation` when live location isn't available, **and** visibly
   flag that the shown location may be stale.

## Done when

- [ ] Nearby hospitals and police load from Overpass — REQ-5.1
- [ ] Unnamed entries and slow or rate-limited responses don't crash the
      panel — REQ-5.1
- [ ] Directions to a chosen service work through `routing_service.dart`,
      with a distance-only fallback — REQ-5.2
- [ ] Default helplines are always visible, independent of Overpass —
      REQ-5.3
- [ ] Tap-to-call works via `url_launcher` — REQ-5.3
- [ ] Last-known location is used as a fallback and marked as possibly
      stale — REQ-5.4
- [ ] Safety disclaimer is present and visible — SRS section 5.2
