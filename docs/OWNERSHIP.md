# docs/OWNERSHIP.md

**This is the canonical record of who owns and builds each feature.**
Where any other document says something different, this file wins —
update it first, then fix the other document to match.

The owner of a feature is the person who builds it, is accountable for
its REQs, and signs off that it is done. Only the owner edits that
feature's folder and service files.

## Current record (from 14 Oct 2026)

| Feature | REQs | Owner | Branch | Folders and files they edit |
| --- | --- | --- | --- | --- |
| App shell, theme, service fakes | — | Vishwa | `flex/app-shell` | `lib/main.dart`, `lib/screens/`, `lib/widgets/`, `lib/theme/`, `lib/dev/` |
| Accounts | REQ-1.1–1.4 | Vishwa | `flex/accounts` | `lib/features/accounts/`, `lib/services/supabase_service.dart` |
| Itinerary | REQ-2.1–2.4 | Vishwa | `flex/itinerary` | `lib/features/itinerary/`, `lib/services/trip_service.dart` |
| Maps & routing | REQ-4.1, 4.2 | Vishwa | `flex/maps` | `lib/features/maps/`, `lib/services/routing_service.dart`, `lib/services/location_service.dart` |
| Recommendations | REQ-6.1–6.4 | Vishwa | `flex/recommendations` | `lib/features/recommendations/`, `db/seed.sql` (recommendations rows) |
| Offline access | REQ-4.3 | Sanjay | `flex/offline` | `lib/features/offline/`, `lib/services/offline_service.dart` |
| Emergency (incl. directions) | REQ-5.1–5.4 | Sanjay | `flex/emergency` | `lib/features/emergency/`, `lib/services/overpass_service.dart` |
| Budget | REQ-3.1–3.5 | Santhosh | `flex/budget` | `lib/features/budget/` |

Shared and frozen for everyone: `db/schema.sql`, `lib/models/`. Changes
there need the whole team's agreement first.

GitHub: Vishwa [@Vishwa-Thangapandiyan](https://github.com/Vishwa-Thangapandiyan),
Sanjay [@SruSanCyborg](https://github.com/SruSanCyborg), Santhosh
[@hehe876](https://github.com/hehe876). Each task is an issue labelled
`owner: <name>`; the numbers are in each person's `team/<name>/PLANNER.md`.

## Why the split looks like this

- **Vishwa takes the most**, including the critical path: the app shell,
  theme and service fakes come first so nobody else has to wait on his
  feature branches.
- **Sanjay and Santhosh have college commitments**, so their load is
  lighter: Sanjay builds Offline and Emergency, Santhosh builds Budget.
- **Both start once the app shell and theme are merged** (Vishwa's first
  task), so their screens match the app's look from day one and their
  AI tools have the design context to read.
- **Directions inside Emergency (REQ-5.2)** now sit with the Emergency
  owner. The old reason for splitting it off — Santhosh having no
  repo-aware AI tool — no longer applies, and keeping it with Emergency
  removes a cross-person dependency. Emergency calls Vishwa's
  `routing_service.dart` through its documented signature, using its fake
  data mode until the real one is merged.

## How parallel work stays parallel

1. Vishwa's first PR (`flex/app-shell`) adds the shell, the theme, and a
   fake-data version of every service in `lib/services/README.md`.
2. After that merges, all three work at the same time. Anyone calling a
   service someone else owns builds against its documented signature and
   fake data — never waits for the other branch.
3. Each owner merges their own PR once the CI check is green. No approval
   from anyone else is required (see `docs/WORKFLOW.md`).
4. When a real service lands, callers need no change: the signature was
   fixed from the start.

## History

Before 14 Oct 2026: Vishwa owned Accounts and Maps & Offline; Sanjay owned
Itinerary, Recommendations and REQ-5.2; Santhosh owned Budget and
Emergency, with Vishwa implementing both on his behalf. Replaced by the
table above.

## Keeping this current

If anything shifts, update the table above in the same change that makes
it true. Don't let this file describe a past arrangement.
