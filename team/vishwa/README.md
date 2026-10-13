# Vishwa Thangapandiyan — 24BCE1415

Builds: the app shell and theme, Accounts (REQ-1.x), Itinerary (REQ-2.x),
Maps & routing (REQ-4.1, 4.2), Recommendations (REQ-6.x), and final
integration. Canonical record: [`docs/OWNERSHIP.md`](../../docs/OWNERSHIP.md).

## How to start a session

From the repository root, run `claude` and send:

```
Read AGENTS.md, then team/vishwa/README.md and team/vishwa/PLANNER.md.
Find my next unticked task, read its feature README, show me the plan,
then build it on the right flex/ branch, verify it, and open the PR.
```

## First: the app shell (`flex/app-shell`) — everyone else starts after this

Sanjay and Santhosh start building the moment this merges, so it comes
before everything else. It contains no feature logic:

1. **Supabase project.** Create it, run `db/schema.sql` then
   `db/seed.sql`, and post the URL and anon key in the group chat.
2. **Theme.** `lib/theme/` with the app's colours, type and spacing, used
   through `Theme.of(context)`. This is the design context the others'
   AI tools read, so give it a short README explaining the choices.
3. **Navigation shell.** `lib/main.dart` and `lib/screens/`: a home with a
   route to every feature, and an empty placeholder screen plus an empty
   Provider in each feature folder (`accounts`, `itinerary`, `maps`,
   `offline`, `emergency`, `budget`, `recommendations`), already
   registered in `main.dart`. After this PR, each owner fills in their own
   files and nobody needs to edit `main.dart`.
4. **Fake data mode.** `lib/dev/fake_data.dart` plus every service file
   listed in `lib/services/README.md`, each with its exact documented
   signature and a body that returns fake data. The app must run with
   `--dart-define=USE_FAKE_DATA=true`, or with no Supabase config at all,
   instead of throwing. Update `RUN.md` to match.
5. **A smoke test** in `test/` so CI's `flutter test` has something to run.

Done when: the app launches in fake data mode, every feature screen is
reachable, `flutter analyze` is clean, CI is green, and the PR is merged.

## Then: your features

Specs and "done when" lists:

- [`lib/features/accounts/README.md`](../../lib/features/accounts/README.md)
- [`lib/features/itinerary/README.md`](../../lib/features/itinerary/README.md)
- [`lib/features/maps/README.md`](../../lib/features/maps/README.md)
- [`lib/features/recommendations/README.md`](../../lib/features/recommendations/README.md)

You also own `trip_service.dart`, `routing_service.dart` and
`location_service.dart`. Sanjay and Santhosh call them, so their
signatures stay exactly as documented.

## Last: integration

Once every feature is merged: place Sanjay's `DownloadTripButton` and
`SavedTripScreen` in the trip flow, check that no fake remains in a normal
run, and walk the full flow end to end (sign up → create a trip → add
stops → set a budget → log an expense → map → download → emergency panel).

## Your personal workflow

Kept in [`docs/WORKFLOW.md`](../../docs/WORKFLOW.md) §2 — a personal
choice, not a team requirement.
