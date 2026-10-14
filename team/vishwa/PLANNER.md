# Vishwa's Planner

The answer when the instructor asks where the project stands. Each line is
a GitHub issue: close it with `Closes #N` in your PR and tick it here in
the same PR. Spec for each feature: its README in `lib/features/`.

Dates were re-planned on 14 Oct 2026 (the original sprint dates had
passed with no feature code merged). Team-wide phases are in `README.md`
§9; each phase is a GitHub milestone.

## Phase A — 14 Oct – 19 Oct: app shell (unblocks everyone)

- [ ] #2 Set up the Supabase project and load the schema
- [x] #3 App shell: theme, navigation and placeholder screens
- [x] #4 Fake data mode for every service, plus a smoke test
- [ ] #5 Update the WBS, Gantt chart and schema comments to the re-plan
- [x] (no issue) Toolbox dev environment: `flutter doctor` clean for Android

## Phase B — 20 Oct – 1 Nov: features (in parallel with Sanjay and Santhosh)

Accounts — `lib/features/accounts/README.md`
- [ ] #6 Sign-up and sign-in, including Google (REQ-1.1)
- [ ] #7 Profile screen (REQ-1.2, REQ-1.3)
- [ ] #8 Human-readable auth errors (REQ-1.4)

Itinerary — `lib/features/itinerary/README.md`
- [ ] #9 Create a trip, and the real `trip_service` (REQ-2.1)
- [ ] #10 Add, edit and delete stops per day (REQ-2.2)
- [ ] #11 Reorder stops within a day (REQ-2.3)
- [ ] #12 Notes on a stop (REQ-2.4)

Maps & routing — `lib/features/maps/README.md`
- [ ] #13 OpenStreetMap with stop markers and attribution (REQ-4.1)
- [ ] #14 Road routing through `routing_service` (REQ-4.2)
- [ ] #15 `location_service` and location permissions

Recommendations — `lib/features/recommendations/README.md`
- [ ] #16 Seed real places for 3–5 destinations (REQ-6.1)
- [ ] #17 Ranked feed with filters (REQ-6.1, 6.2, 6.4)
- [ ] #18 Add a recommendation to the itinerary (REQ-6.3)

## Phase C — 2 Nov – 8 Nov: integration and testing

- [ ] #31 Offline widgets in place, fakes gone, full flow end to end

## Phase D — 9 Nov – 20 Nov: release and viva

- [ ] #34 Google OAuth redirect and release APK
- [ ] #35 Report, user guide and viva prep: RLS, the `auth.users`/`profiles`
      split, why recommendations are a database ranking, the offline scope

## Blockers

| Date | Blocker | Status |
| --- | --- | --- |
| | | |
