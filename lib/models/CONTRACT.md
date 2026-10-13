# lib/models/ — the data contract

**This file is FROZEN.** These are the exact shapes every branch reads and
writes. If you need a field that isn't here, say so in the group chat
before adding it — a silent change breaks the other two people's branches,
not just yours. This applies even if you're using an AI tool that "helpfully"
suggests a different field name. It doesn't know the contract. This file
does.

**How to use this if you're pasting into a chat with no repo access:** copy
this whole file, plus the one class you need, into your first message. It
is written to be unambiguous with zero other context.

Project: Smart Travel Planning Assistant and Budget Management System.
Stack: Flutter + Dart, Supabase (Postgres + Auth), Provider for state. Each
class below is a plain Dart data class — a constructor, `fromJson`, and
`toJson` — matching one table in `db/schema.sql` column-for-column. No
class does anything beyond hold data and convert to/from the JSON Supabase
sends and expects.

Conventions used in every class:

- A Postgres `uuid` becomes a Dart `String`.
- A Postgres `timestamptz` becomes a Dart `DateTime`, via
  `DateTime.parse(...)` / `.toIso8601String()`.
- A Postgres `date` (no time component) also becomes a Dart `DateTime`, but
  serializes back with `DateFormat('yyyy-MM-dd')` from `package:intl`, not
  `toIso8601String()` — that would send a full timestamp where Postgres
  expects a bare date.
- A Postgres `numeric` becomes a Dart `double`.
- A Postgres `jsonb` becomes a Dart `Map<String, dynamic>?`.
- A Postgres `text[]` becomes a Dart `List<String>?`.
- A Postgres `time` becomes a Dart `String?` in `"HH:mm:ss"` format — Dart
  has no built-in wire-safe time type, and pulling in a package just for
  this wasn't worth it. Parse it yourself for display.
- A nullable Postgres column is a nullable Dart field (`?`, no default
  except where the table itself has a `default` clause, e.g.
  `default_currency`).

---

## UserProfile — table `profiles`

Owner: Vishwa (Accounts, REQ-1.1–1.4). File: `lib/models/user_profile.dart`.

| Field | Type | Column | Notes |
| --- | --- | --- | --- |
| `id` | `String` | `id` | Same UUID as `auth.users.id`. Not a separate identity. |
| `fullName` | `String?` | `full_name` | |
| `defaultCurrency` | `String` | `default_currency` | Defaults to `'INR'` if the constructor doesn't get one. |
| `preferences` | `Map<String, dynamic>?` | `preferences` | Free-form jsonb. Can be used to sort recommendations; does not shape trip generation (there is none). |
| `createdAt` | `DateTime` | `created_at` | |

Supabase Auth creates `auth.users` on sign-up but **not** a matching
`profiles` row — the app must insert one right after sign-up, or every new
user's profile screen loads empty.

---

## Trip — table `trips`

Owner: Vishwa (Itinerary, REQ-2.1–2.4). File: `lib/models/trip.dart`.

| Field | Type | Column | Notes |
| --- | --- | --- | --- |
| `id` | `String` | `id` | |
| `userId` | `String` | `user_id` | References `auth.users.id`. |
| `destination` | `String` | `destination` | |
| `startDate` | `DateTime` | `start_date` | Date only. Serializes as `yyyy-MM-dd`. |
| `endDate` | `DateTime` | `end_date` | Date only. Serializes as `yyyy-MM-dd`. |
| `latitude` | `double?` | `latitude` | Set at trip creation; Maps needs it. |
| `longitude` | `double?` | `longitude` | Set at trip creation; Maps needs it. |
| `createdAt` | `DateTime` | `created_at` | |

`Trip` also exposes a computed getter `numberOfDays` (`endDate.difference
(startDate).inDays + 1`). **Days are not a database table.** Do not create
one. Calculate day headings from these two dates every time, so an edited
end date can never leave stale day rows behind.

---

## ItineraryItem — table `itinerary_items`

Owner: Vishwa (Itinerary, REQ-2.1–2.4). File: `lib/models/itinerary_item.dart`.

| Field | Type | Column | Notes |
| --- | --- | --- | --- |
| `id` | `String` | `id` | |
| `tripId` | `String` | `trip_id` | FK to `trips.id`. |
| `dayNumber` | `int` | `day_number` | Which day of the trip this stop belongs to; the user picks it. Nothing computes it. |
| `title` | `String` | `title` | |
| `locationName` | `String?` | `location_name` | |
| `latitude` | `double?` | `latitude` | Consumed by Maps for markers. |
| `longitude` | `double?` | `longitude` | Consumed by Maps for markers. |
| `startTime` | `String?` | `start_time` | `"HH:mm:ss"` text, nullable. |
| `orderIndex` | `int` | `order_index` | Position within the day. Reordering (REQ-2.3) swaps this value between two adjacent rows — arrow buttons are sufficient, drag-and-drop is not required. |
| `notes` | `String?` | `notes` | |
| `createdAt` | `DateTime` | `created_at` | |

---

## Budget — table `budgets`

Owner: Santhosh (Budget, REQ-3.1–3.5). File: `lib/models/budget.dart`.

| Field | Type | Column | Notes |
| --- | --- | --- | --- |
| `id` | `String` | `id` | |
| `tripId` | `String` | `trip_id` | FK to `trips.id`. |
| `category` | `String` | `category` | e.g. `"food"`, `"transport"`. Unique per `(trip_id, category)` in the DB. |
| `allocatedAmount` | `double` | `allocated_amount` | What was PLANNED, not what was spent. |

There is deliberately no "amount spent" field anywhere in this class or the
table. See `Expense` below.

---

## Expense — table `expenses`

Owner: Santhosh (Budget, REQ-3.1–3.5). File: `lib/models/expense.dart`.

| Field | Type | Column | Notes |
| --- | --- | --- | --- |
| `id` | `String` | `id` | |
| `tripId` | `String` | `trip_id` | FK to `trips.id`. |
| `category` | `String` | `category` | Should match a `Budget.category` for the same trip, but nothing enforces that at the DB level. |
| `amount` | `double` | `amount` | |
| `spentOn` | `DateTime` | `spent_on` | Date only. Serializes as `yyyy-MM-dd`. |
| `description` | `String?` | `description` | |

**Never store a running total.** Compute spend-per-category with `SELECT
category, SUM(amount) FROM expenses WHERE trip_id = ? GROUP BY category`,
every time the balances screen loads. A stored total goes stale the moment
an expense is edited or deleted.

---

## Recommendation — table `recommendations`

Owner: Vishwa (Recommendations, REQ-6.1–6.4). File: `lib/models/recommendation.dart`.

| Field | Type | Column | Notes |
| --- | --- | --- | --- |
| `id` | `String` | `id` | |
| `destination` | `String` | `destination` | |
| `name` | `String` | `name` | |
| `category` | `String` | `category` | |
| `description` | `String?` | `description` | |
| `rating` | `double?` | `rating` | |
| `priceLevel` | `int?` | `price_level` | |
| `tags` | `List<String>?` | `tags` | Postgres `text[]`. |
| `latitude` | `double?` | `latitude` | Copied onto a new `ItineraryItem` when the user taps "add to trip". |
| `longitude` | `double?` | `longitude` | Copied onto a new `ItineraryItem` when the user taps "add to trip". |
| `imageUrl` | `String?` | `image_url` | |

Rows are hand-seeded in `db/seed.sql` by Vishwa. There is no live places
API and no scraping. Ranking is a plain `ORDER BY rating DESC` — that is
the complete, required deliverable for REQ-6.4, not a placeholder for a
future ML model.

---

## EmergencyContact — table `emergency_contacts`

Owner: Sanjay (Emergency, REQ-5.1–5.4). File: `lib/models/emergency_contact.dart`.

| Field | Type | Column | Notes |
| --- | --- | --- | --- |
| `id` | `String` | `id` | |
| `region` | `String?` | `region` | |
| `serviceName` | `String` | `service_name` | |
| `phoneNumber` | `String` | `phone_number` | |
| `isDefault` | `bool` | `is_default` | `true` for national numbers (112, 100, 108, 101, ...). Defaults to `false`. |

These come from Supabase, never from Overpass, and must render even if
Overpass fails, is rate-limited, or returns nothing.

---

## OfflinePack — table `offline_packs`

Owner: Sanjay (Offline, REQ-4.3). File: `lib/models/offline_pack.dart`.

| Field | Type | Column | Notes |
| --- | --- | --- | --- |
| `id` | `String` | `id` | |
| `userId` | `String` | `user_id` | |
| `tripId` | `String` | `trip_id` | FK to `trips.id`. Unique per `(user_id, trip_id)` in the DB. |
| `guideText` | `String?` | `guide_text` | |
| `staticMapUrl` | `String?` | `static_map_url` | One static image, not a pannable tile cache. |
| `downloadedAt` | `DateTime` | `downloaded_at` | |

This row only records that a download happened and where the static assets
live. The actual offline copy (trip, itinerary items, guide text) is
written into Hive on the phone, not into this table.

---

## LastKnownLocation — table `last_known_location`

Owner: Sanjay (Emergency, REQ-5.4). File: `lib/models/last_known_location.dart`.

| Field | Type | Column | Notes |
| --- | --- | --- | --- |
| `userId` | `String` | `user_id` | Primary key — one row per user, overwritten on every update. No history. |
| `latitude` | `double` | `latitude` | |
| `longitude` | `double` | `longitude` | |
| `recordedAt` | `DateTime` | `recorded_at` | Compare this to `DateTime.now()` to decide whether the fallback position is stale. The class does not do this comparison itself — the caller (Emergency's location logic) does, and must show a visible "may be out of date" flag when it does. |

---

## Not modeled yet

Every table in `db/schema.sql` has a model above. There is no `days` table
and there should never be one — see `Trip.numberOfDays`.

## Changing this contract

Don't. If a feature genuinely needs a new field: post it in the group
chat, get agreement, then one person updates `db/schema.sql`, the matching
class here, and this file in the same PR. Until that PR merges, build
against what's written above — not against what you wish existed.
