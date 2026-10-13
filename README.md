# Smart Travel Planning Assistant and Budget Management System

A Flutter mobile app combining itinerary planning, budget tracking, map
navigation with offline access, emergency assistance, and destination
recommendations.

Software engineering course project — Vellore Institute of Technology,
Chennai.

| Name | Reg. No | Builds |
| --- | --- | --- |
| Vishwa Thangapandiyan | 24BCE1415 | App shell, Accounts, Itinerary, Maps & routing, Recommendations |
| Sanjay Sivakumar | 24BCE1948 | Offline access, Emergency Assistance |
| Santhosh S | 24BCE5169 | Budget & Expenses |

Canonical record: [`docs/OWNERSHIP.md`](docs/OWNERSHIP.md).

**Why Flutter, not a web app.** This project started as a React + Vite web
app. It was rebuilt as Flutter because background location tracking — the
foundation for a later "Trip Mode" and live-sharing direction the team
wants to build toward — is not possible in a web app on any platform.
Flutter can do it; a browser tab can't. To be precise about scope:
background tracking itself is **not built and not in the core plan** — see
`PROJECT-UNDERSTANDING.md` Part 10 and Part 13. It's a stretch goal. The
platform decision was made now, ahead of actually needing it, so the app
isn't rebuilt a second time later.

---

## 0. New here? Read this first

**Do not start coding from this file.** Open [`START-HERE.md`](START-HERE.md) —
it covers cloning the repo, making a branch, pushing your work, and
opening a pull request, written for people who have never used Git.

Then open your own folder in [`team/`](team/). Your brief has the one
prompt to give your AI tool (Claude Code or Codex); it reads
[`AGENTS.md`](AGENTS.md) and the files it points to, so the requirements
come along with every task.

---

## 1. What this project is

Planning a trip means juggling four or five apps — maps in one, a budget
spreadsheet in another, itinerary notes in a third. This app puts them in
one place.

A user signs in, creates a trip with dates and a destination, builds a
day-wise itinerary, sets a budget split across categories, and logs
expenses as they spend. Itinerary stops appear on a map with routing.
Before travelling, they can download a destination for offline use so the
app still works when the connection drops. If something goes wrong, an
emergency panel lists nearby hospitals and police stations with one-tap
calling. A recommendations feed suggests places near the destination that
can be added straight to the itinerary.

Six features, all specified in the SRS. Nothing outside those six ships in
v1.

Read `PROJECT-UNDERSTANDING.md` for how these six features actually fit
together end to end — it's the authoritative description of the system,
more detailed and more current than this file.

## 2. What we are honest about

Worth keeping in mind for every document, PR, and the viva. These are the
project's real limits, and stating them plainly beats being caught
overclaiming:

- **Nothing generates an itinerary.** The user builds it manually, one
  stop at a time — either by typing it in or by tapping a recommendation.
  There is no planning engine, and none was ever designed. See
  `PROJECT-UNDERSTANDING.md` Part 3.
- **Budget and itinerary are entirely disconnected systems.** A stop has
  no price attached to it. Adding expensive places to a day changes
  nothing on the budget screen until the user separately, manually logs an
  expense. Nothing checks whether a day's stops are even close to each
  other geographically.
- **Offline mode is not a fully pannable offline map.** It is cached
  itinerary data, cached guide text, and one static map image per
  destination. Still a legitimate offline mode — just sized to what three
  students finish in a semester.
- **We are not load-testing at production scale.** The SRS says so
  explicitly. The app should feel responsive for one user; that is the
  bar.
- **Offline coverage is limited to a handful of chosen destinations**, not
  everywhere.
- **The recommendation engine is a database-driven ranking**, not a
  trained ML model. REQ-6.4 deliberately allows this. Any similarity
  ranking we add is a ranking function, and we describe it that way.
- **This is not a certified emergency-dispatch system.** The Emergency
  panel states that in a real emergency the user should also call local
  services directly.
- **Background location tracking is a stretch goal, not a built feature.**
  See the note at the top of this file and `PROJECT-UNDERSTANDING.md`
  Part 10.

## 3. Tech stack

| Layer | Choice | Why |
| --- | --- | --- |
| App | Flutter + Dart | One codebase, targeting Android first — and unlike a web app, it can access background location, which is the reason this isn't a browser app anymore (see the note above). |
| State management | Provider | Holds data several screens share (e.g. budget totals) so they redraw together when it changes, without passing data down by hand. |
| Auth + Database | Supabase (free tier) | Free Postgres, built-in auth with Google sign-in, auto-generated API. We do not hand-roll password hashing or sessions. |
| Maps | flutter_map + OpenStreetMap | Completely free, **no credit card required**. Google Maps' free tier still demands a billing account — a pointless blocker for a student project. |
| Routing | OSRM public demo server | Free, no key, fine for a demo. |
| Emergency data | Overpass API | Free, no key, queries OpenStreetMap for hospitals and police stations. |
| Offline storage | Hive | A small database that lives on the phone, so cached trip data survives with no connection. |

**On "where is the backend?"** — Supabase generates an API over our
Postgres database and enforces per-user access with Row Level Security.
That is the application server / API layer described in SRS Section 2.1.
We are not skipping the backend; we are using a hosted one instead of
writing our own. Defensible in the viva, and it saves weeks.

## 4. Repo structure

```
smart-travel-assistant/
├── README.md                  this file
├── START-HERE.md               git + flutter setup guide, read this first
├── RUN.md                       exact flutter run command, with Supabase keys
├── FILE-STRUCTURE.md            build spec — what lives where and why
├── AGENTS.md                    rules every AI agent and contributor follows
├── CLAUDE.md                    imports AGENTS.md, plus Claude Code specifics
├── .claude/settings.json        shared Claude Code settings (attribution off)
├── .github/                     PR template, CODEOWNERS, CI workflow
├── .gitignore
├── pubspec.yaml                fixed dependency list — no additions without asking
├── analysis_options.yaml
│
├── team/                      per-person briefs and planners
│   ├── vishwa/                App shell, Accounts, Itinerary, Maps, Recommendations
│   ├── sanjay/                Offline, Emergency
│   └── santhosh/               Budget
│
├── db/
│   ├── schema.sql             ALL tables for ALL features. Frozen — see rule 2.
│   └── seed.sql                demo data for recommendations and helplines
│
├── lib/
│   ├── main.dart               entry point, Provider setup, Supabase init
│   │
│   ├── models/                 ★ the frozen interface contract
│   │   ├── CONTRACT.md         read this before touching any model
│   │   └── *.dart               one class per table in db/schema.sql
│   │
│   ├── services/                anything that talks to the outside world
│   │   └── README.md            documents every service's signature
│   │
│   ├── providers/               state, one per feature area
│   │
│   ├── features/                one folder per feature, one owner each; README = spec
│   │   ├── accounts/            Vishwa    — REQ-1.x
│   │   ├── itinerary/            Vishwa    — REQ-2.x
│   │   ├── budget/                Santhosh  — REQ-3.x
│   │   ├── maps/                   Vishwa    — REQ-4.1, 4.2
│   │   ├── offline/                 Sanjay    — REQ-4.3
│   │   ├── emergency/               Sanjay    — REQ-5.x
│   │   └── recommendations/          Vishwa    — REQ-6.x
│   │
│   ├── screens/                 top-level navigation
│   └── widgets/                  shared UI
│
└── docs/                      SRS, WBS, Gantt, diagrams — NOT pushed to GitHub
    ├── srs/  wbs/  gantt/  images/
```

`docs/` contents are gitignored on purpose — they are binary submission
artifacts, not source. The folder structure stays tracked so a fresh clone
shows where things belong. See [`docs/README.md`](docs/README.md).

## 5. Ownership and branches

Each feature has one owner who builds it on its own branch. **Only touch
your own folders.** Branches are named `flex/<page-or-feature>`, never by
contributor.

The table of owners, branches and the exact folders each person edits is
in [`docs/OWNERSHIP.md`](docs/OWNERSHIP.md) — the canonical source, kept
in one place so it can't disagree with itself.

## 6. Ground rules

1. **Touch only your own feature folder.** If something in
   `lib/screens/`, `lib/widgets/`, `lib/models/`, or `db/schema.sql` needs
   changing, say so in the group chat first. Silent edits to shared files
   are how three people end up with three broken branches.

2. **`db/schema.sql` is frozen once we run it.** Every table for every
   feature is already in there. If your feature needs a column that does
   not exist, tell the group before adding it — a schema change breaks
   everyone's queries, not just yours.

3. **`lib/models/` is frozen.** These are the shared Dart classes every
   branch reads and writes against — see `lib/models/CONTRACT.md`.
   Changing a field breaks the other two branches silently. Same rule as
   the schema, because it's the same problem one layer up.

4. **Never touch `.env` or hardcode a key.** There is no `.env` file in
   this project — Supabase config is passed with `--dart-define` at run
   time, see `RUN.md`. (The Supabase anon key is public by design and safe
   in a compiled app — Row Level Security is what protects the data. The
   `service_role` key is a different story and must never appear
   anywhere.)

5. **Pull before you start, every time.** `git checkout main && git pull`
   before making a branch. Skipping this is the number-one cause of merge
   conflicts.

6. **Small PRs, often.** One PR per working piece — "login screen works" —
   not one giant PR at the end of the month. Merge your own PR once CI is
   green; no approval is needed.

7. **Update your planner.** Each `team/<name>/PLANNER.md` has dated
   milestones. Tick things off in the same PR that finishes them. When the
   instructor asks where we are, that file is the answer.

8. **Blocked for more than a day? Say so** in the group chat.

9. **No AI attribution** in commits or PRs — see `AGENTS.md` rule 8.

## 7. Build order

The features used to form a waiting chain (Accounts → Itinerary → Maps →
Emergency). That chain is broken on purpose:

```
1. App shell + theme + fake services  (Vishwa)   ← the only thing anyone waits for
       │
       ├── Accounts, Itinerary, Maps & routing, Recommendations  (Vishwa)
       ├── Offline, Emergency                                    (Sanjay)
       └── Budget                                                (Santhosh)
              all in parallel, each against the fake services
       │
2. Integration: real services replace fakes, full flow tested  (everyone)
```

Every service has a fixed signature in `lib/services/README.md` and a
fake version from the app shell, so nobody waits for anyone else's
branch. See `docs/OWNERSHIP.md`, "How parallel work stays parallel".

## 8. Running it locally

Full instructions with troubleshooting are in [`START-HERE.md`](START-HERE.md).
Short version:

```bash
git clone <repo-url>
cd smart-travel-assistant
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

The real values for the two `--dart-define` flags are posted in the group
chat by Vishwa. See [`RUN.md`](RUN.md) for the full command and why there's
no `.env` file to copy.

## 9. Timeline

Semester runs to **20 November 2026**. Planning, SRS, and design
documentation are complete. We are in **Phase 4: Implementation**.

Re-planned on 14 Oct 2026: the original sprint dates (Aug 24 – Oct 18)
passed with no feature code merged, and the work was redistributed (see
`docs/OWNERSHIP.md`).

| Phase | Dates | Focus |
| --- | --- | --- |
| A | Oct 14 – Oct 19 | App shell, theme, fake services, Supabase project (Vishwa). Others set up. |
| B | Oct 20 – Nov 1 | All features in parallel (everyone) |
| C | Nov 2 – Nov 8 | Real services replace fakes, integration, testing |
| D | Nov 9 – Nov 20 | Release APK, user guide, final report, viva prep |

The Gantt chart in `docs/gantt/` still shows the original sprints and
needs updating to match.
