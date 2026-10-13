# Sanjay Sivakumar — 24BCE1948

Builds: Offline access (REQ-4.3) and Emergency assistance (REQ-5.1–5.4).
Canonical record: [`docs/OWNERSHIP.md`](../../docs/OWNERSHIP.md).

## When to start

**After Vishwa's app shell (`flex/app-shell`) is merged.** That gives you
the theme, a placeholder screen and Provider already in your folders, and
fake data for every service — so from then on you never wait for anyone.

## How to start a session

From the repository root, run `claude` and send:

```
Read AGENTS.md, then team/sanjay/README.md and team/sanjay/PLANNER.md.
Find my next unticked task, read its feature README, show me the plan,
then build it on the right flex/ branch, verify it, and open the PR.
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
