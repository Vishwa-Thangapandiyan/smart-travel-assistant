# FILE-STRUCTURE.md

**Originally a build spec for the React scaffold; now a reference for
where things belong in the Flutter rebuild.** The structure below is what
exists in the repo today. Read this together with `README.md` and
`CLAUDE.md` before adding anything new.

---

## 1. Target tree

```
smart-travel-assistant/
├── README.md                          project overview, stack, ground rules
├── START-HERE.md                        git + Flutter setup guide
├── RUN.md                                exact `flutter run` command and the two --dart-define keys
├── FILE-STRUCTURE.md                     this file
├── AGENTS.md                              rules for every AI agent and contributor (Codex reads it)
├── CLAUDE.md                              imports AGENTS.md, plus Claude Code specifics
├── .claude/settings.json                  shared Claude Code settings: attribution off
├── .gitignore
├── pubspec.yaml                          fixed dependency list — no additions without asking
├── analysis_options.yaml
│
├── .github/
│   ├── pull_request_template.md
│   ├── CODEOWNERS                        tags each folder's owner on a PR
│   └── workflows/ci.yml                  flutter analyze (+ test) on every PR
│
├── docs/                                  contents gitignored, structure tracked
│   ├── .gitignore
│   ├── README.md                          ⚠ flags the SRS/diagrams as web-app-era and out of date
│   ├── srs/.gitkeep
│   ├── wbs/.gitkeep
│   ├── gantt/.gitkeep
│   └── images/.gitkeep
│
├── team/
│   ├── README.md
│   ├── vishwa/
│   │   ├── README.md                     brief: what he builds, when, and the prompt for his AI tool
│   │   └── PLANNER.md
│   ├── sanjay/
│   │   ├── README.md
│   │   └── PLANNER.md
│   └── santhosh/
│       ├── README.md
│       ├── PLANNER.md
│       └── AI-PROMPT-PACK.md             old copy-paste fallback; superseded by Codex
│
├── db/
│   ├── schema.sql                        ALL tables for ALL features. FROZEN.
│   └── seed.sql                           demo data for recommendations and helplines
│
└── lib/
    ├── main.dart                          entry point: Supabase.initialize + Provider tree
    │
    ├── models/                            ★ THE FROZEN INTERFACE CONTRACT
    │   ├── CONTRACT.md                    every class, every field — read before touching any model
    │   ├── trip.dart
    │   ├── itinerary_item.dart
    │   ├── budget.dart
    │   ├── expense.dart
    │   ├── recommendation.dart
    │   ├── emergency_contact.dart
    │   ├── user_profile.dart
    │   ├── offline_pack.dart
    │   └── last_known_location.dart
    │
    ├── services/                          anything that talks outside the phone
    │   ├── README.md                      fixes every service's signature; fake versions come with the app shell
    │   ├── supabase_service.dart          OWNER: Vishwa
    │   ├── trip_service.dart              OWNER: Vishwa — read-only trips for Offline, Budget, Maps
    │   ├── routing_service.dart           OWNER: Vishwa — OSRM; Emergency calls it for directions
    │   ├── location_service.dart          OWNER: Vishwa
    │   ├── offline_service.dart           OWNER: Sanjay
    │   └── overpass_service.dart          OWNER: Sanjay
    │
    ├── providers/                         state, one per feature area (built by owners as features land)
    │
    ├── features/                          one folder per feature, one owner each; README = spec + checklist
    │   ├── accounts/README.md             Vishwa    — REQ-1.x
    │   ├── itinerary/README.md            Vishwa    — REQ-2.x
    │   ├── budget/README.md               Santhosh  — REQ-3.x
    │   ├── maps/README.md                 Vishwa    — REQ-4.1, 4.2
    │   ├── offline/README.md              Sanjay    — REQ-4.3
    │   ├── emergency/README.md            Sanjay    — REQ-5.1–5.4
    │   └── recommendations/README.md      Vishwa    — REQ-6.x
    │
    ├── screens/                           top-level navigation (built as features land)
    └── widgets/                           shared UI (built as features land)
```

Folders that hold only future work (`providers/`, `screens/`, `widgets/`,
and the `.dart` files under `services/`) currently contain nothing but a
`.gitkeep` — that's expected. They belong to feature owners; this scaffold
only documents where their code goes.

---

## 2. Project facts

**Project:** Smart Travel Planning Assistant and Budget Management System
**Institution:** Vellore Institute of Technology, Chennai — software
engineering course project
**Timeline:** implementation runs 24 Aug 2026 → 20 Nov 2026

**Team and ownership:** Vishwa Thangapandiyan (24BCE1415), Sanjay
Sivakumar (24BCE1948), Santhosh S (24BCE5169). Who builds which feature,
on which branch, editing which folders, is recorded in one place only:
[`docs/OWNERSHIP.md`](docs/OWNERSHIP.md). Branches are named by feature
(`flex/<page-or-feature>`), never by contributor.

**Six features (SRS sections):** 4.1 User Account Management
(`accounts`, REQ-1.x) · 4.2 Trip and Itinerary Planning (`itinerary`,
REQ-2.x) · 4.3 Budget and Expense Management (`budget`, REQ-3.x) · 4.4
Maps, Navigation & Offline Access (`maps` for REQ-4.1–4.2, `offline` for
REQ-4.3) · 4.5 Emergency Assistance (`emergency`, REQ-5.x) · 4.6
Destination Recommendations (`recommendations`, REQ-6.x).

**Stack (fixed — do not substitute):** Flutter + Dart, Provider,
Supabase (auth + Postgres), flutter_map + OpenStreetMap, OSRM public demo
server for routing, Overpass API for emergency services, Hive for
offline. No custom backend. No API keys beyond the Supabase anon key. No
credit card anywhere. Full dependency list in `pubspec.yaml` — see
`CLAUDE.md` for the "do not substitute" table.

**Schedule:** re-planned on 14 Oct 2026 into phases A–D — see
`README.md` §9.

**Dependencies:** the only thing anyone waits for is Vishwa's app shell
(theme plus a fake version of every service). After it merges, every
feature builds in parallel against the fixed service signatures in
`lib/services/README.md`; real services replace the fakes during
integration. See `README.md` §7.

---

## 3. lib/models/ — the frozen contract

Every table in `db/schema.sql` has exactly one matching Dart class in
`lib/models/`. `lib/models/CONTRACT.md` documents every field, its type,
and its owner. It is the most load-bearing file in the repo: without a
fixed, written contract, each person's AI tool would invent its own field
names and no branch would compile against anyone else's work.

**Do not change a class in `lib/models/` without raising it in the group
chat first.** A silent field rename breaks the other two branches, not
just yours.

---

## 4. lib/services/ — the service contract

`lib/services/README.md` documents the public method signature of every
service file before that file exists, and the app shell ships a fake
version of each — so a feature can call a service someone else owns
(for example, Emergency calling Vishwa's `routing_service.dart`) without
waiting for their branch. Build against the documented signature; if it
needs to change, say so in the group chat first, same rule as the models.

---

## 5. Secrets — the answer to "are the Supabase keys safe?"

Short version: **the anon key is safe, the `service_role` key is not, and
neither one gets committed to the repo either way.**

This project does not use a `.env` file. Flutter has no built-in
equivalent, and adding a package (`flutter_dotenv` or similar) just to
simulate one wasn't worth a new dependency. Instead, both Supabase values
are passed at build/run time with `--dart-define`, and
`lib/main.dart` reads them with `String.fromEnvironment`. See `RUN.md`
for the exact command.

| Key | Safe in a compiled app? | Safe to commit? |
| --- | --- | --- |
| Supabase project URL | Yes | Harmless, but still don't hardcode it in a committed file |
| Supabase anon/public key | **Yes, by design** | Technically harmless, still keep it out of the repo |
| `service_role` key | **Never** | **Never.** Bypasses all security. |

The anon key is *public by design* — anyone who decompiles a shipped
Flutter APK can find it. That is expected and fine, because the anon key
alone grants nothing. **Row Level Security is what actually protects the
data**, which is why `db/schema.sql` enables it on every table. An app
with RLS switched off is wide open regardless of how well the key is
hidden.

So the reason the keys never land in a committed file is habit and blast
radius, not because the anon key is a secret: a repo where secrets are
casually committed trains bad reflexes, and the `service_role` key is a
different story entirely.

**Rules for whoever builds this:** never write a real key into any
committed file — not a script, not a checked-in `launch.json`, nowhere.
`RUN.md` documents where local, gitignored config for your editor can
live if you want to avoid retyping the command. If the `service_role` key
ever leaks, rotate it in the Supabase dashboard immediately.

---

## 6. The context-loading step

Every team member's brief has one prompt for their AI tool (Claude Code
or Codex). The tool reads `AGENTS.md`, the brief, the planner and the
feature README, so a task never arrives without the requirements behind
it. See `START-HERE.md` §7.

---

## 7. Build rules

1. **`db/schema.sql` and `PROJECT-UNDERSTANDING.md` are frozen.** Neither
   gets edited casually.
2. **`lib/models/` is frozen.** See §3.
3. **Never create `.env`.** This project doesn't use one — see §5 and
   `RUN.md`.
4. **Do not run `flutter pub get`, `flutter create`, or install anything**
   as part of scaffolding work — that's for whoever actually builds a
   feature to run locally.
5. **Feature folders under `lib/features/*/` get a README and nothing
   else.** The code inside belongs to that folder's owner.
6. **Do not invent facts.** Names, dates, REQ numbers, and the schema all
   come from §2 above, `db/schema.sql`, and `PROJECT-UNDERSTANDING.md`. If
   something is genuinely unspecified — see `PROJECT-UNDERSTANDING.md`
   Part 13 — leave it flagged as undecided rather than guessing.
