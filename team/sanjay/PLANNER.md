# Sanjay's Planner

The answer when the instructor asks where the project stands. Each line is
a GitHub issue: close it with `Closes #N` in your PR and tick it here in
the same PR. Specs: `lib/features/emergency/README.md` and
`lib/features/offline/README.md`.

Dates were re-planned on 14 Oct 2026. Team-wide phases are in
`README.md` §9; each phase is a GitHub milestone.

## Before you start (any time before 20 Oct)

- [ ] Accept the GitHub collaborator invite
- [ ] Flutter, Git and an Android emulator or phone working
      (`START-HERE.md` §1)
- [ ] Repo cloned; app runs in fake data mode once #3 and #4 are merged
      (`RUN.md`)

## Phase B — from the app shell merge (#3, #4) to 1 Nov

Emergency — branch `flex/emergency`
- [x] #19 Nearby hospitals and police via Overpass (REQ-5.1)
- [x] #20 Default helplines and tap-to-call (REQ-5.3)
- [x] #21 Directions to the nearest service (REQ-5.2)
- [x] #22 Last-known-location fallback (REQ-5.4)
- [x] #23 Safety disclaimer (SRS section 5.2)
- [x] #48 Email my emergency contact, sent from the phone's mail app

Offline — branch `flex/offline`
- [ ] #24 Agree where guide text and the static map come from (team decision)
- [ ] #25 Download a trip to Hive and record it (REQ-4.3)
- [ ] #26 `DownloadTripButton` and `SavedTripScreen` (REQ-4.3)

## Phase C — 2 Nov – 8 Nov: integration and testing

- [ ] #32 Emergency and Offline against the real services

## Phase D — 9 Nov – 20 Nov: release and viva

- [ ] #36 Report, user guide and viva prep: why offline is one static map
      image, why helplines come from the database and not Overpass

## Blockers

| Date | Blocker | Status |
| --- | --- | --- |
| | | |
