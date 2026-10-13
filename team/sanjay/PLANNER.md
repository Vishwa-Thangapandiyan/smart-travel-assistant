# Sanjay's Planner

The answer when the instructor asks where the project stands. Tick items
in the same PR that finishes them. Specs:
`lib/features/offline/README.md` and `lib/features/emergency/README.md`.

Dates were re-planned on 14 Oct 2026. Team-wide phases are in
`README.md` §9.

## Before you start (any time before 20 Oct)

- [ ] Flutter, Git and an Android emulator or phone working
      (`START-HERE.md` §1)
- [ ] GitHub username sent to Vishwa for collaborator access
- [ ] Repo cloned; app runs in fake data mode once the app shell is merged
      (`RUN.md`)

## Phase B — from the app shell merge to 1 Nov: Emergency

- [ ] `overpass_service.dart` real: hospitals and police near a position
- [ ] Slow, rate-limited and unnamed Overpass results handled, no crash
- [ ] Default helplines always visible; tap-to-call works
- [ ] Directions to a chosen service via `routing_service.dart`, with a
      distance-only fallback
- [ ] Last-known location fallback, flagged as possibly stale
- [ ] Safety disclaimer visible
- [ ] `flex/emergency` merged

## Phase B (continued): Offline

- [ ] Guide text and static map source agreed with the team (see the open
      question in the Offline README)
- [ ] `offline_service.dart`: download to Hive, `OfflinePack` row written
- [ ] `DownloadTripButton` and `SavedTripScreen` built
- [ ] Tested in Airplane Mode, including a never-downloaded trip
- [ ] `flex/offline` merged

## Phase C — 2 Nov – 8 Nov: integration and testing

- [ ] Works against Vishwa's real services, not the fakes
- [ ] Overpass slow/empty and a stale location tested on a real device

## Phase D — 9 Nov – 20 Nov: release and viva

- [ ] User guide and final report sections for Offline and Emergency
- [ ] Viva prep: why offline is one static map image, why helplines come
      from the database and not Overpass

## Blockers

| Date | Blocker | Status |
| --- | --- | --- |
| | | |
