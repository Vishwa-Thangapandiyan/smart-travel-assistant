# Sanjay Sivakumar — 24BCE1948

Builds: Offline access (REQ-4.3) and Emergency assistance (REQ-5.1–5.4).
Canonical record: [`docs/OWNERSHIP.md`](../../docs/OWNERSHIP.md).

GitHub: [@SruSanCyborg](https://github.com/SruSanCyborg)

## When to start

**After Vishwa's app shell is merged — issues #3 and #4.** That gives you
the theme, a placeholder screen and Provider already in your folders, and
fake data for every service — so from then on you never wait for anyone.

## Your issues

| Issue | What | Phase |
| --- | --- | --- |
| #19 | Emergency: nearby hospitals and police via Overpass (REQ-5.1) | B |
| #20 | Emergency: default helplines and tap-to-call (REQ-5.3) | B |
| #21 | Emergency: directions to the nearest service (REQ-5.2) | B |
| #22 | Emergency: last-known-location fallback (REQ-5.4) | B |
| #23 | Emergency: safety disclaimer (SRS 5.2) | B |
| #24 | Offline: agree where guide text and the static map come from | B |
| #25 | Offline: download a trip to Hive and record it (REQ-4.3) | B |
| #26 | Offline: `DownloadTripButton` and `SavedTripScreen` (REQ-4.3) | B |
| #32 | Integration: Emergency and Offline against the real services | C |
| #36 | Report, user guide and viva prep | D |

All open: [your issues on GitHub](https://github.com/Vishwa-Thangapandiyan/smart-travel-assistant/issues?q=is%3Aopen+label%3A%22owner%3A+sanjay%22).
Close each one by writing `Closes #N` in the PR that finishes it.

## How to start a session

From the repository root, run `claude` and send:

```
Read AGENTS.md, then team/sanjay/README.md and team/sanjay/PLANNER.md.
Find my next unticked task, read its feature README, show me the plan,
then build it on the right flex/ branch, verify it, and open the PR that closes its issue.
```

That's the whole setup. Attribution is already switched off by the
repo's `.claude/settings.json`.

## Your features

Specs and "done when" lists:

- [`lib/features/offline/README.md`](../../lib/features/offline/README.md)
  — branch `flex/offline`
- [`lib/features/emergency/README.md`](../../lib/features/emergency/README.md)
  — branch `flex/emergency`

You own `lib/services/offline_service.dart` and
`lib/services/overpass_service.dart`. You call Vishwa's `trip_service`,
`routing_service` and `location_service` through their documented
signatures in `lib/services/README.md` — use their fake data until the
real ones merge. Don't edit his files; if something's missing, ask.

## Merging

When CI is green, merge your own PR. No approval needed.
