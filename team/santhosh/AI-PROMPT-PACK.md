# AI Prompt Pack

**Superseded (14 Oct 2026).** Santhosh now uses Codex, which reads the
repository itself — follow `team/santhosh/README.md` instead. This pack
stays only as a fallback for times without Codex. **Its Emergency prompts
no longer apply**: Emergency belongs to Sanjay now (see
`docs/OWNERSHIP.md`). The Budget prompts still describe the right task,
but `lib/features/budget/README.md` is the current spec if they ever
disagree.

Copy-paste prompts for free-tier ChatGPT or Claude. You don't have a
subscription, so every message has to count — these are pre-loaded with
the context a paid, repo-aware tool would read automatically.

**Full rewrite note:** this pack used to be React/JS. The project moved to
Flutter — a React prompt would actively teach the wrong patterns now (a
`useState` hook, a `.jsx` file extension, `npm install` instructions all
apply to a language and framework this project no longer uses). Every
prompt below is Flutter/Dart, and includes the exact model class from
`lib/models/CONTRACT.md` alongside the schema, so the AI you're pasting
into has the real shape of the data, not something it guesses at.

## How to use it

- **Start a fresh chat per task.** Old chats accumulate context that isn't
  relevant to the new question and eats into what the model can hold.
- **Copy the whole block**, including the stack description, schema, and
  model class — don't trim it to save characters. Missing context is what
  causes a wrong-shaped answer that costs you a second message to fix.
- **Bundle multiple questions into one message** where you can — "build the
  screen, and also handle the empty-category case" beats two separate
  messages.
- **Ask for complete files, not fragments.** A fragment you have to merge
  by hand yourself is a second message waiting to happen when it doesn't
  quite fit.

---

## Prompt 1: Budget setup screen

```
I'm building a Flutter (Dart, no other cross-platform framework) feature
for a student project — a travel budget tracker. Stack: Flutter, Provider
for state management, Supabase for auth/database (already set up — I get
the client from `Supabase.instance.client`). No new pub dependencies —
use only what's already in pubspec.yaml (supabase_flutter, provider, plus
the usual Flutter SDK widgets).

Relevant table (db/schema.sql):

create table budgets (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id) on delete cascade,
  category text not null,
  allocated_amount numeric not null,
  unique (trip_id, category)
);

Matching Dart model (lib/models/budget.dart) — use this exact class, do
not invent your own field names:

class Budget {
  final String id;
  final String tripId;
  final String category;
  final double allocatedAmount;

  const Budget({
    required this.id,
    required this.tripId,
    required this.category,
    required this.allocatedAmount,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      category: json['category'] as String,
      allocatedAmount: (json['allocated_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'category': category,
      'allocated_amount': allocatedAmount,
    };
  }
}

Build a complete Flutter screen (StatefulWidget or a Provider-backed
widget, your choice, but use Provider for the state — not a bare
setState-only widget): given a tripId, let the user add categories (e.g.
Food, Stay, Transport) with an allocated amount each, save them as
`Budget` rows to Supabase, and list the categories already saved for this
trip. Handle the case where a category is entered twice for the same trip
(the unique constraint will reject it — show a plain error message, don't
crash).

Give me the complete file and comments explaining anything non-obvious —
I have to explain this code in a viva, so a comment on *why* something is
done a certain way is more useful than one restating what the line does.
```

## Prompt 2: Expense form

```
Same project as before — Flutter, Provider, Supabase, no new pub
dependencies.

Relevant table (db/schema.sql):

create table expenses (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id) on delete cascade,
  category text not null,
  amount numeric not null,
  spent_on date not null,
  description text
);

Matching Dart model (lib/models/expense.dart):

import 'package:intl/intl.dart';

final DateFormat _dateOnly = DateFormat('yyyy-MM-dd');

class Expense {
  final String id;
  final String tripId;
  final String category;
  final double amount;
  final DateTime spentOn;
  final String? description;

  const Expense({
    required this.id,
    required this.tripId,
    required this.category,
    required this.amount,
    required this.spentOn,
    this.description,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      spentOn: DateTime.parse(json['spent_on'] as String),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'category': category,
      'amount': amount,
      'spent_on': _dateOnly.format(spentOn),
      'description': description,
    };
  }
}

Build a complete Flutter widget: a form to log an expense (category,
amount, date via a date picker, optional description) for a given
tripId, saving as an `Expense` row to Supabase, plus a list of expenses
already logged for that trip, most recent first. Category should be a
dropdown populated from the trip's existing `budgets` rows (query
Supabase for `budgets` where `trip_id` matches, list distinct
categories).

Give me the complete file and comments on anything non-obvious — I need
to be able to explain this code in a viva.
```

## Prompt 3: Balances and threshold alerts

```
Same project — Flutter, Provider, Supabase, no new pub dependencies.

Relevant tables (db/schema.sql):

create table budgets (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id) on delete cascade,
  category text not null,
  allocated_amount numeric not null,
  unique (trip_id, category)
);

create table expenses (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id) on delete cascade,
  category text not null,
  amount numeric not null,
  spent_on date not null,
  description text
);

Use the Budget and Expense Dart model classes from Prompts 1 and 2 above
(same field names, same fromJson/toJson) — I've already got those files
in the project, don't redefine them differently.

Build a complete Flutter widget, backed by a Provider `ChangeNotifier`
(call it something like `BudgetProvider`), that shows, per category for a
trip: the allocated amount, the amount spent (SUM of Expense.amount
grouped by category — do NOT store a running total anywhere, compute it
live on every load by querying Supabase), the remaining balance, and a
visible warning when spending has crossed 90% of the allocation for that
category. Guard against divide by zero when a category's allocatedAmount
is 0.

Give me the complete provider class plus the widget that uses it, and
comments on anything non-obvious for a viva explanation. Keep the 90%
check as plain if-statements on data already fetched — no external
notification service, no background task.
```

## Prompt 4: Nearby emergency services (Overpass)

```
Same project — Flutter, Provider, no new pub dependencies beyond
`http` (already in pubspec.yaml) for the API call.

I need a complete Dart service file (lib/services/overpass_service.dart)
plus a Flutter widget that uses it. The service should query the Overpass
API for nearby hospitals (amenity=hospital) and police stations
(amenity=police) given a latitude/longitude, and return a list of simple
objects with a name (nullable) and coordinates. Use this shape for the
result type:

class OverpassPlace {
  final String? name;
  final String amenityType; // "hospital" or "police"
  final double latitude;
  final double longitude;
  const OverpassPlace({
    this.name,
    required this.amenityType,
    required this.latitude,
    required this.longitude,
  });
}

The widget should list them with name and straight-line distance from the
given position. Handle: Overpass being slow or rate-limited (show a
loading/error state, don't hang forever), and OSM entries with no name
tag (show "Unnamed hospital" or "Unnamed police station" instead of a
blank line). This is a genuine free, keyless public API — no API key
handling needed.

Give me both files and comments on anything non-obvious for a viva
explanation.
```

## Prompt 5: Emergency contacts and tel: links

```
Same project — Flutter, Provider, Supabase, no new pub dependencies
beyond `url_launcher` (already in pubspec.yaml) for the phone call.

Relevant table (db/schema.sql):

create table emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  region text,
  service_name text not null,
  phone_number text not null,
  is_default boolean not null default false
);

Matching Dart model (lib/models/emergency_contact.dart):

class EmergencyContact {
  final String id;
  final String? region;
  final String serviceName;
  final String phoneNumber;
  final bool isDefault;

  const EmergencyContact({
    required this.id,
    this.region,
    required this.serviceName,
    required this.phoneNumber,
    this.isDefault = false,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      region: json['region'] as String?,
      serviceName: json['service_name'] as String,
      phoneNumber: json['phone_number'] as String,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region': region,
      'service_name': serviceName,
      'phone_number': phoneNumber,
      'is_default': isDefault,
    };
  }
}

Build a complete Flutter widget that lists emergency contacts from this
table (national defaults always shown first, e.g. 112, 100, 108, 101) as
tappable rows that call `launchUrl(Uri(scheme: 'tel', path:
phoneNumber))` from `package:url_launcher/url_launcher.dart` — no other
telephony package. This list must still render correctly even if a
separate "nearby services" widget (different task, uses Overpass) fails
to load — treat this as independent, not dependent on Overpass being up.
Also render a fixed, always-visible disclaimer: that this is not a
certified emergency-dispatch system, and in a genuine life-threatening
emergency the user should call local services directly.

Give me the complete file and comments on anything non-obvious for a viva
explanation.
```

## Prompt 6: Last-known-location fallback

```
Same project — Flutter, Provider, Supabase, plus `geolocator` (already in
pubspec.yaml) for GPS. No new pub dependencies.

Relevant table (db/schema.sql):

create table last_known_location (
  user_id uuid primary key references auth.users(id),
  latitude double precision not null,
  longitude double precision not null,
  recorded_at timestamptz not null default now()
);

Matching Dart model (lib/models/last_known_location.dart):

class LastKnownLocation {
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  const LastKnownLocation({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  factory LastKnownLocation.fromJson(Map<String, dynamic> json) {
    return LastKnownLocation(
      userId: json['user_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}

Build a complete Dart function/class (e.g. a `useLocation`-style helper —
in Flutter this means a plain async function or a small
`ChangeNotifier`, not a React hook) that: tries to get the device's live
position first via `Geolocator.getCurrentPosition()`, handling permission
requests; if that fails or is denied, falls back to reading the user's
`LastKnownLocation` from Supabase; and in the fallback case, returns a
flag indicating the location may be stale (compare `recordedAt` to
`DateTime.now()` — if it's more than, say, 30 minutes old, flag it) so the
calling widget can show a visible "this location may be out of date"
warning. When a live position IS obtained successfully, write/update it
to `last_known_location` in Supabase for next time.

Give me the complete file and comments on anything non-obvious for a viva
explanation.
```

---

## Debugging prompt template

When something breaks, don't describe it from memory — paste the exact
error. A full error message beats a summary of what you think it means;
summarizing loses the one detail (a line number, a specific null value)
that would have made the fix obvious in one pass.

```
I'm working on [file name/path] in a Flutter + Supabase + Provider
project.

Exact error message:
[paste the full error, including stack trace if there is one]

What I expected to happen:
[expected behaviour]

What actually happened:
[actual behaviour]

Relevant code:
[paste the function or widget involved — not the whole file unless it's short]

What I've already tried:
[anything you changed before asking, so we don't repeat it]
```

---

## Message-saving habits

| Inefficient | Efficient instead |
| --- | --- |
| Pasting one error, waiting, pasting the next related error separately | Bundle all related errors from one test run into a single message |
| Asking for a snippet, then asking again for the surrounding file | Ask for the complete file up front |
| Describing an error from memory | Paste the exact error text and stack trace |
| Asking "why doesn't this work" with no code attached | Always attach the actual code you're asking about |
| Iterating fix → test → new chat → re-explain everything | Stay in the same chat until the task is fully done |
| Asking the AI to guess your schema or model shape | Paste the relevant `CREATE TABLE` block AND the matching Dart class every time |

---

## The escalation rule

**Stuck on the same error for more than 30 minutes? Post it in the group
chat.** Vishwa or Sanjay can run it through their Pro session and hand back
a fix in one exchange where you might burn your remaining free messages on
the same bug. This is the intended workflow for your two features, not a
sign you're behind — see the ground rules in the main `README.md`.
