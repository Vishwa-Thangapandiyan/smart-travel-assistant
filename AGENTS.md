# AGENTS.md

Instructions for any AI coding agent working in this repository: Codex
reads this file automatically, and `CLAUDE.md` imports it for Claude Code.
Humans should read it too. It is short on purpose; the detail lives in the
files it points to.

Documentation authority, most to least:

1. `PROJECT-UNDERSTANDING.md` — product requirements and system
   behaviour. Wins any disagreement with anything below.
2. This file — hard rules every contributor and agent follows.
3. `docs/OWNERSHIP.md` — who owns and builds each feature (canonical).
4. `DESIGN.md` — how every screen looks: colours, type, components, and
   a reference picture of each screen in `design/screens/`.
5. Feature READMEs (`lib/features/<name>/README.md`) — the spec and
   "done when" checklist for each feature.
6. `team/<name>/` — each person's brief and dated planner.

## What this project is

Smart Travel Planning Assistant and Budget Management System — a Flutter
mobile app (Android-first): sign in, create a trip, build a day-by-day
itinerary by hand, set a budget split by category and log expenses, see
stops on a map with routing, download a trip for offline use, and find
nearby hospitals and police with one-tap calling. All logic runs on the
phone. Supabase stores rows and answers queries; there is no server-side
code anywhere. Software engineering course project, VIT Chennai.

## The stack — fixed

Flutter + Dart, Provider, Supabase (Postgres + Auth, free tier), Hive,
flutter_map + OpenStreetMap, Nominatim (destination coordinates),
OSRM public demo server, Overpass API, Wikimedia Commons (place photos),
geolocator, url_launcher (`tel:`), http, intl. The full dependency list is
`pubspec.yaml`. **Do not add a package** — if a task seems to need one,
stop and ask the team first.

## Hard rules

1. **Stay in your own folders.** Each feature folder and service file has
   one owner — see `docs/OWNERSHIP.md`. If a change outside your folders is
   needed, stop and say so instead of making it.
2. **`db/schema.sql` is frozen.** Every table already exists. A schema
   change breaks everyone's queries.
3. **`lib/models/` is frozen** — the shared contract, see
   `lib/models/CONTRACT.md`. Never change a field name or type. A new field
   is a schema change: same rule as above.
4. **Never write a key into a committed file.** There is no `.env`;
   Supabase config is passed with `--dart-define` (see `RUN.md`). The
   `service_role` key must never appear anywhere.
5. **No new dependencies** beyond `pubspec.yaml`.
6. **Boring, readable code.** Every line has to be defensible when a
   student explains it in a viva. No cleverness, no abstraction for a use
   case that doesn't exist, comments only where the why isn't obvious.
7. **Do not invent excluded functionality.** See the next section.
8. **No AI attribution, ever.** Do not add `Co-authored-by`,
   `Co-Authored-By`, `Claude-Session`, "Generated with …" or any other
   AI-tool trailer or footer to commits or pull request descriptions. Commit
   as the human whose machine you run on, with their git identity.

## What does NOT exist — do not build or imply these

From `PROJECT-UNDERSTANDING.md` Part 13:

- **Itinerary auto-generation.** The user builds the itinerary by hand,
  typing stops or tapping a recommendation. There is no planning engine.
- **Any link between budget and itinerary.** A stop has no price. Nothing
  checks whether a day's stops are geographically sensible.
- **Any ML model.** Recommendations are a plain database `ORDER BY` on a
  hand-seeded table. A similarity ranking, if built, is a scoring
  function, not a trained model.
- **Any server-side logic.** Flutter does all the thinking.
- **Background location tracking**, "Trip Mode", watchdog check-ins and
  location sharing are out of scope. One-off position lookups and caching
  the last known position are in scope.
- **Pannable offline maps.** Offline is cached trip data, guide text and
  one static map image.

Still undecided — leave flagged, don't guess: editing a trip while
offline, when cached data expires, SMS emergency alerts.

## How to work a task

1. `git checkout main && git pull`.
2. Find your next task: the first unticked item in `team/<name>/PLANNER.md`.
   Every item is a GitHub issue (`#N`); read it with `gh issue view N` if
   the GitHub CLI is available. Its full spec and "done when" list are in
   `lib/features/<feature>/README.md`. Skip an issue whose "Starts after"
   or "Needs" line isn't satisfied yet and take the next one.
3. Branch: `git checkout -b flex/<feature>` (feature or page name, never a
   person's name — see `docs/WORKFLOW.md`).
4. Before writing code, read: the feature README, `lib/models/CONTRACT.md`,
   `lib/services/README.md`, and the tables you use in `db/schema.sql`.
   For any screen, also read `DESIGN.md` and look at that screen's picture
   in `design/screens/` (the table in `DESIGN.md` §7 says which). Use the
   app theme from `lib/theme/` — never hard-code colours or fonts.
   Show the plan before large changes.
5. Build against the service signatures in `lib/services/README.md`. If a
   service you call belongs to someone else and isn't real yet, use its
   fake data mode — never wait for their branch.
6. Verify before calling anything done: `flutter analyze` reports no
   issues, `flutter test` passes, and the app runs. Say plainly what you
   could not verify.
7. Commit only the files you meant to change (`git add <paths>`, not
   `git add .`), with a message that says what changed. No attribution
   trailers (rule 8).
8. Push and open a pull request into `main` using the template, with
   `Closes #N` in the description for every issue it finishes — GitHub
   then closes the issue when the PR merges. Tick the same items in your
   planner in the same PR. When the **CI check is green you may merge your
   own PR** — no one else's approval is required.

## Where things are

| Need | File |
| --- | --- |
| Who owns what, who builds what | `docs/OWNERSHIP.md` |
| Your tasks and dates | `team/<name>/README.md`, `team/<name>/PLANNER.md`, GitHub issues labelled `owner: <name>` |
| A feature's spec and checklist | `lib/features/<feature>/README.md` |
| How screens look | `DESIGN.md`, `design/screens/`, `design/tokens.json` |
| Service signatures (incl. other people's) | `lib/services/README.md` |
| Data classes | `lib/models/CONTRACT.md` |
| Database | `db/schema.sql`, `db/seed.sql` |
| Running the app | `RUN.md` |
| Git help from zero | `START-HERE.md` |
| Team-wide process | `docs/WORKFLOW.md` |
