# Vishwa's Planner

The answer when the instructor asks where the project stands. Tick items
in the same PR that finishes them. Spec for each feature: its README in
`lib/features/`.

Dates were re-planned on 14 Oct 2026 (the original sprint dates had
passed with no feature code merged). Team-wide phases are in `README.md`
§9.

## Phase A — 14 Oct – 19 Oct: app shell (unblocks everyone)

- [ ] Toolbox dev environment working: `flutter doctor` clean for Android
- [ ] Supabase project created; `db/schema.sql` and `db/seed.sql` run
- [ ] Supabase URL and anon key posted in the group chat
- [ ] Sanjay and Santhosh invited as collaborators; `main` protected
- [ ] `flex/app-shell`: theme, navigation shell, placeholder screen and
      Provider in every feature folder, fake data mode for every service,
      smoke test — merged with CI green
- [ ] Group chat told: "app shell is merged — start"

## Phase B — 20 Oct – 1 Nov: features (in parallel with Sanjay and Santhosh)

- [ ] Accounts merged — `lib/features/accounts/README.md`
- [ ] Itinerary merged, with real `trip_service.dart` —
      `lib/features/itinerary/README.md`
- [ ] Maps & routing merged, with real `routing_service.dart` and
      `location_service.dart` — `lib/features/maps/README.md`
- [ ] Recommendations merged, with seed data —
      `lib/features/recommendations/README.md`

## Phase C — 2 Nov – 8 Nov: integration and testing

- [ ] Offline's `DownloadTripButton` and `SavedTripScreen` placed in the
      trip flow
- [ ] No fake data left in a normal run
- [ ] Full flow works end to end: sign up → trip → stops → budget →
      expense → map → download → emergency
- [ ] Edge cases: email already used, wrong password, map with zero
      stops, OSRM unreachable — no crash, clear message

## Phase D — 9 Nov – 20 Nov: release and viva

- [ ] Google OAuth redirect configured in Supabase for the real app scheme
- [ ] Release APK built (`RUN.md`)
- [ ] User guide and final report sections for your features
- [ ] Viva prep: RLS, the `auth.users`/`profiles` split, why recommendations
      are a database ranking, the offline scope

## Blockers

| Date | Blocker | Status |
| --- | --- | --- |
| | | |
