# PROJECT-UNDERSTANDING.md

**What this document is:** a reference for building your mental model of how the Smart Travel Planner works as one system.

**What it is not:** an SRS, a technical specification, or an implementation guide. There is almost no code here on purpose.

**How to use it:** read Parts 1–3 first, then jump around. Part 13 is the honesty section — what actually exists versus what is still just an idea. Read that one before you plan any work.

One example trip runs through the entire document so nothing floats:

> **Vishwa travels Chennai → Bangalore, 20–23 November, budget ₹15,000.**

---

# PART 1 — THE ENTIRE APP IN ONE STORY

Vishwa is going to Bangalore for three days. Right now, without this app, he does this: Google Maps in one tab for directions, a Notes app for what he wants to see, a spreadsheet for what he is spending, Zomato for food, and a panicked Google search for "hospital near me" if something goes wrong. Five apps, none of which know about each other.

The app replaces those five with one.

He opens it, signs in, and creates a trip: Bangalore, 20–23 November. The app now knows where he is going and for how long. He sets a budget — ₹15,000 total, split across food, transport, stay, and activities. He builds out what he wants to do each day, either by typing places in himself or by browsing a suggestions list and tapping to add them. Those places show up as pins on a map, and the app can draw a route between them. Before he leaves, he downloads the trip so it still works when his signal dies. During the trip, he logs what he spends and the app tells him when he is running out of money in a category. If something goes wrong, one screen shows nearby hospitals and police stations, and a button dials emergency services directly.

That is the whole product. Six things, one place.

## The real end-to-end journey

Your prompt sketched a flow. Here it is corrected against what we have actually designed. **Two boxes in your version do not exist** and are marked below.

```text
       User opens app
              │
              ▼
    Signs up / logs in                    ← Accounts
              │
              ▼
    Creates a trip                        ← Itinerary
    (destination + dates)
              │
              ▼
    Sets a budget                         ← Budget
    (total, split by category)
              │
              ├──────────────────┐
              ▼                  ▼
   Adds itinerary items    Browses recommendations   ← Itinerary + Recommendations
   by typing them in       and taps to add them
              │                  │
              └────────┬─────────┘
                       ▼
            Views stops on a map              ← Maps
            Draws a route between them
                       │
                       ▼
            Downloads trip for offline        ← Offline
                       │
                       ▼
       ═══════ TRIP BEGINS ═══════
                       │
              ┌────────┼────────┐
              ▼        ▼        ▼
          Logs      Opens    Loses signal,
        expenses  emergency   reads cached
                    panel        trip
```

**What is NOT in that flow, despite being in your version:**

- ❌ **"Gets an itinerary"** — nothing generates an itinerary. The user builds it. See Part 3.
- ❌ **"Preferences shape the trip"** — preferences exist on the profile and can influence which recommendations sort to the top, but they do not shape the trip itself.
- ⚠️ **"Eventually uses location tracking"** — discussed, agreed as a stretch goal, not designed. See Part 10.

---

# PART 2 — THE MOVIE

Two parallel stories for every action: what the user sees, and what the software is quietly doing.

Before the scenes, three characters you need to know, because everything below is them passing things to each other:

| Character | Plain English |
| --- | --- |
| **Flutter** | The app on the phone. Every screen, every button, every piece of logic that decides what to show. It runs *on the phone*, not on a server. |
| **Supabase** | A database on the internet with a permanent memory. Flutter asks it to remember things and to hand them back later. |
| **Hive** | A small storage box *inside the phone*. Copies of things, kept for when the internet is gone. |

## Scene 1 — Opening the app

```text
USER                          SYSTEM
────                          ──────
Taps the app icon
                              Flutter starts up
                              Asks Supabase: "is anyone already
                              signed in on this phone?"
                                        │
                                        ▼
                              Supabase checks the saved session token
                                        │
                    ┌───────────────────┴───────────────────┐
                    ▼                                       ▼
              Token valid                             No token / expired
                    │                                       │
                    ▼                                       ▼
        Flutter shows the trip list             Flutter shows the login screen
```

A **session token** is a slip of paper the app keeps saying "this phone already proved who it is." It saves you logging in every single time.

## Scene 2 — Logging in

```text
USER                          SYSTEM
────                          ──────
Types email + password
Taps "Sign in"
                              Flutter collects both values
                                        │
                                        ▼
                              Sends them to Supabase Auth
                                        │
                                        ▼
                              Supabase hashes the password and
                              compares it to the stored hash
                                        │
                    ┌───────────────────┴──────────────┐
                    ▼                                  ▼
                 Match                              No match
                    │                                  │
                    ▼                                  ▼
        Returns a session token           Returns an error code
                    │                                  │
                    ▼                                  ▼
        Flutter saves it, opens          Flutter shows "Email or password
        the trip list                    is incorrect" under the field
```

Note what Flutter *never* sees: the stored password. It never had it, cannot retrieve it, and does no security work itself. Supabase Auth handles all of that. This is deliberate — hand-rolled authentication is where student projects get their security wrong.

## Scene 3 — Creating a trip

```text
USER                          SYSTEM
────                          ──────
Taps "New trip"
                              Flutter shows an empty form

Destination: Bangalore
Start: 20 Nov
End: 23 Nov
Taps "Create"
                              Flutter validates:
                                • destination not empty?
                                • end date not before start date?
                                        │
                              ┌─────────┴─────────┐
                              ▼                   ▼
                          Invalid              Valid
                              │                   │
                              ▼                   ▼
                  Red text under the      Sends to Supabase:
                  offending field         { destination, start, end, user_id }
                  Nothing is sent                 │
                                                  ▼
                                        Supabase writes a row into `trips`
                                        and generates an ID for it
                                                  │
                                                  ▼
                                        Returns the saved trip, ID included
                                                  │
                                                  ▼
                                        Flutter opens the trip detail screen,
                                        showing 4 empty days (20, 21, 22, 23)
```

Notice the days were never stored. **Flutter calculated them** from the two dates. The database holds two dates; the four-day layout is worked out on the phone every time the screen opens. Storing what you can calculate is how data goes stale.

## Scene 4 — Adding an itinerary item

```text
USER                          SYSTEM
────                          ──────
On Day 1, taps "Add"
                              Flutter shows a form

Title: Cubbon Park
Time: 09:00
Taps "Save"
                              Flutter sends to Supabase:
                              { trip_id, day_number: 1,
                                title, start_time, order_index: 0 }
                                        │
                                        ▼
                              Row written into `itinerary_items`
                                        │
                                        ▼
                              Flutter re-fetches Day 1's items,
                              sorted by order_index, and redraws
```

`trip_id` is the important field. It is the string that means *this stop belongs to that trip*. Without it, the row is an orphan — a place with no trip attached. More on this in Part 7.

## Scene 5 — Logging an expense

```text
USER                          SYSTEM
────                          ──────
Taps "Add expense"
Amount: ₹450
Category: Food
Taps "Save"
                              Row written into `expenses`
                                        │
                                        ▼
                              Flutter immediately re-fetches ALL
                              expenses for this trip and adds them
                              up, grouped by category
                                        │
                                        ▼
                              Compares each total against what was
                              allocated to that category
                                        │
                                        ▼
                              Food: ₹4,600 spent of ₹5,000
                              → that is 92%, over the 90% line
                                        │
                                        ▼
Sees the food bar turn        Flutter shows a warning banner
amber with a warning
```

The crucial detail: **there is no "amount spent" stored anywhere.** It is recalculated from scratch every single time. Add ₹450 → re-add every expense → get the new total. This sounds wasteful and is exactly right, because a stored total goes wrong the moment someone edits or deletes an expense, and then your budget silently lies to you.

---

# PART 3 — HOW ITINERARY PLANNING ACTUALLY WORKS

**This is the section where your mental model and the actual design disagree, so read it slowly.**

## The honest answer first

> **Nothing generates an itinerary. The user builds it manually, one item at a time.**

Your prompt asked how the app turns *"Bangalore + 3 days + ₹15,000 + food/history/nature"* into a day-by-day plan. It does not. That feature was never designed, never specified, and does not exist anywhere in what we have agreed to build.

What exists instead is two separate things that feel adjacent but are not the same:

```text
WHAT YOU ARE PICTURING              WHAT WE ACTUALLY DESIGNED
──────────────────────              ─────────────────────────

User gives preferences              User creates an empty trip
        │                                    │
        ▼                                    ▼
System thinks                       User types in stops themselves
        │                                    │
        ▼                                    ▼
Complete Day 1/2/3 plan             OR browses a suggestions list
appears                             and taps ones they like
                                             │
                                             ▼
                                    Each tap adds ONE stop to
                                    ONE day the user picks
```

The second is a **list with an add button**. The first is a **planning engine**. They are different products, and only one of them is on the table.

## Now, your fifteen questions, answered honestly

**1. What information does the user provide?**
Destination, start date, end date. That is all a trip requires. Optionally a budget, and optionally preferences on their profile.

**2. Where is it stored?**
The trip in the `trips` table, the budget in `budgets`, preferences on the user's `profiles` row. All in Supabase.

**3. How do we find possible places to visit?**
From a table called `recommendations` that **your team fills in by hand**. Vishwa picks three to five destinations you will actually demo, and types in ten to fifteen real places for each — name, category, rating, price level, coordinates.

**4. Where do those places come from?**
Vishwa. Typing them. This is worth sitting with: there is no live places API, no scraping, no external feed. It is a hand-written list in a database table.

**5. How are places selected?**
The user taps ones they like. There is no automatic selection.

**6. How does the system decide Day 1 vs Day 2 vs Day 3?**
It does not. The user chooses the day when they add the item.

**7. How does distance between locations affect the itinerary?**
It does not. Nothing checks whether your Day 1 stops are sensibly close together. You could put a stop in Bangalore and the next one in Mysore back to back and the app would not object. The map will happily draw you the 3-hour route between them.

**8. How does budget affect it?**
It does not. **Budget and itinerary are entirely disconnected systems.** A stop has no price attached to it. Adding twelve expensive restaurants to Day 1 changes nothing about your budget screen until you separately, manually log expenses.

**9. How do user preferences affect it?**
This is the one honest "maybe." Preferences can be used to sort the recommendations feed — showing food places nearer the top if the user listed food as an interest. That is a `sort by` on a database query, not planning.

**10. Where does AI/recommendation logic fit?**
Nowhere, currently. The design explicitly permits a plain database ranking with no machine learning. A tag-similarity ranking was discussed as an *optional* stretch, and if built, it is a scoring function — not a trained model, and it should be described that way and no more grandly.

**11. Does Supabase generate the itinerary?** No. Supabase stores rows and hands them back. It contains no planning logic.

**12. Does Flutter generate it?** No. Flutter draws screens and sends what the user typed.

**13. Does an external API generate it?** No. None of OSRM, Overpass, or OpenStreetMap has any concept of an itinerary.

**14. What is finally saved?** One row per stop in `itinerary_items`: which trip, which day, title, optional location and coordinates, optional time, and a position number for ordering within the day.

**15. How does the user edit it afterward?** Tap an item to edit, swipe or long-press to delete, arrows or drag to reorder within a day.

## So what does the app actually give the user?

Reframe it and it stops feeling thin:

```text
It is a STRUCTURED NOTEBOOK, not a PLANNER.

  A notes app knows nothing about your notes.
  This knows: which trip, which day, where on a map,
  what it costs you, and it still works offline.
```

That is genuinely useful and honestly scoped. Automatic generation could be built later — it is a real feature with real design questions behind it (how do you weight distance against interest, what happens when the user hates the output, how do you handle a place being closed on Tuesdays) — but it is not what exists, and building a document that pretends otherwise would set you up to be caught out in a review.

---

# PART 4 — THE MAP, WATCHED HAPPENING

Four names get mixed together in your head. They do genuinely different jobs.

## The one-line version of each

| Thing | What it actually is | Physical analogy |
| --- | --- | --- |
| **OpenStreetMap (OSM)** | A free, worldwide *dataset* of what exists where — roads, buildings, hospitals — plus pre-drawn map images of it | The paper the map is printed on |
| **flutter_map** | Flutter code that displays those images and lets you pan, zoom, and drop pins | The frame holding the paper, and the pins you stick in it |
| **OSRM** | A routing engine — give it two points, it computes the driving path along real roads | The person who traces the route with a pen |
| **Supabase** | Stores *your* stops and coordinates | Your handwritten list of places |

## The distinction you specifically asked about

```text
MAP DISPLAY                          ROUTE CALCULATION
───────────                          ─────────────────

"Show me a picture of Bangalore"     "How do I drive from Cubbon Park
                                      to Bangalore Palace?"

Handled by: OSM tiles                Handled by: OSRM
            + flutter_map

Returns: image squares               Returns: a list of coordinates
                                     tracing the road, plus distance
                                     and duration

Knows about roads? NO — it is        Knows about roads? YES — that is
just a picture of roads              its entire job

Needs your itinerary? NO             Needs your itinerary? YES, the
                                     two endpoints come from it
```

A **tile** is one square image of the map, roughly 256×256 pixels. Your screen shows a grid of them. Zoom in and different, more detailed tiles get fetched. That is all a map display is: a grid of pictures that swaps as you move.

The mental trap you are in: thinking the map "knows" things. It does not. **The map is a picture.** Everything intelligent — where the pins go, what route connects them — comes from somewhere else and gets drawn *on top* of the picture.

## Concrete: Day 1 in Bangalore

```text
   Cubbon Park  →  Bangalore Palace  →  Vidhana Soudha


STEP 1 — Get the stops
────────────────────────
   Flutter ──── "give me Day 1 of trip abc-123" ───▶ Supabase
                                                        │
   Flutter ◀─── 3 rows, each with lat/long ─────────────┘


STEP 2 — Draw the map picture
──────────────────────────────
   flutter_map works out which tiles cover that area
        │
        └─── requests tile images ───▶ OpenStreetMap tile servers
                                                │
             screen fills with map ◀────────────┘

   ⚠️  At this point there are NO pins and NO route.
       Just a picture of Bangalore.


STEP 3 — Add the pins
──────────────────────
   Flutter takes the 3 coordinate pairs from Step 1
   and tells flutter_map to place markers there.

   Nothing was fetched. Nobody was asked. Flutter already
   had the coordinates; it just drew dots at those positions.


STEP 4 — Draw the route
────────────────────────
   Flutter ─── "route between these 3 points?" ───▶ OSRM
                                                      │
   Flutter ◀── road path + 4.2km + 14 min ────────────┘
        │
        └── hands the path to flutter_map, which draws
            a line following the roads
```

Four steps, three different sources, and only Steps 2 and 4 touch the internet for map purposes. If OSRM is down, you still get a map with pins — you just lose the line between them. Worth knowing, because it means the failure is partial, not total.

---

# PART 5 — EVERY FEATURE AS A USER STORY

Six features. These are the real ones, nothing invented to pad the list.

---

```text
FEATURE: ACCOUNTS

PROBLEM
  Everything else is personal. Your trips, your budget, your
  spending. Without accounts there is no "your" — one shared
  blob everyone can see.

USER DOES
  Signs up with email + password, or taps "Continue with Google".
  Later, edits their name, default currency, and interests.

APP DOES
  Hands the credentials to Supabase Auth. Never handles the
  password itself. Stores the returned session token so the
  user stays signed in across restarts.

DATA FLOW
  Flutter ──credentials──▶ Supabase Auth ──token──▶ Flutter
                                  │
                                  └── creates a row in `auth.users`

  ⚠️  It does NOT create the matching `profiles` row. The app
      must do that itself right after signup, or the profile
      screen loads blank for every new user.

SERVICES
  Supabase Auth. Google as an optional sign-in provider.

DATABASE
  `auth.users` (managed by Supabase — you never touch it)
  `profiles`   (yours — name, currency, preferences)

RESULT
  A signed-in user whose ID stamps everything they create.
```

---

```text
FEATURE: TRIP & ITINERARY

PROBLEM
  "What am I doing on Tuesday?" lives in your head or a
  scattered notes file, disconnected from anything else.

USER DOES
  Creates a trip. Adds stops to specific days. Edits, deletes,
  reorders them.

APP DOES
  Validates dates, saves the trip, calculates how many days it
  spans, renders one section per day, and keeps items sorted by
  their position number within each day.

DATA FLOW
  Flutter ──{destination, dates}──▶ `trips`
  Flutter ──{trip_id, day, title}──▶ `itinerary_items`
  Flutter ◀──items sorted by day, then position──── Supabase

SERVICES
  Supabase only. No external service is involved in planning.

DATABASE
  `trips`            one row per trip
  `itinerary_items`  one row per stop

RESULT
  A day-by-day list the user built themselves — which the map
  and offline features both read from.
```

---

```text
FEATURE: BUDGET & EXPENSES

PROBLEM
  You find out you overspent after the trip, when it is too
  late to do anything about it.

USER DOES
  Sets a total, splits it into categories, then logs expenses
  as they spend.

APP DOES
  After every single expense, re-fetches all expenses for the
  trip, sums them by category, compares to what was allocated,
  and warns at 90% and again when exceeded.

DATA FLOW
  Flutter ──{amount, category, date}──▶ `expenses`
  Flutter ──"all expenses for this trip"──▶ Supabase
  Flutter ◀──every expense row──────────────┘
       │
       └── adds them up ON THE PHONE, compares, decides to warn

SERVICES
  Supabase only. No notification service — the warning is a
  banner in an already-open screen.

DATABASE
  `budgets`   what you planned per category
  `expenses`  what you actually spent

RESULT
  A live picture of what is left, and a nudge before you blow
  a category rather than after.
```

---

```text
FEATURE: MAPS & ROUTING

PROBLEM
  A list of place names does not tell you where anything is or
  how far apart your day's stops actually are.

USER DOES
  Opens the map. Sees pins. Taps one for a route.

APP DOES
  Pulls coordinates from the itinerary, fetches map tiles,
  drops markers, and asks OSRM for a road path when a route
  is requested.

DATA FLOW
  Supabase ──coordinates──▶ Flutter
  OpenStreetMap ──tile images──▶ flutter_map
  OSRM ──road path + distance + duration──▶ Flutter

SERVICES
  OpenStreetMap (pictures), OSRM (routing). Both free, neither
  needs an API key.

DATABASE
  Reads `itinerary_items`. Writes nothing.

RESULT
  Stops shown in real space, with a real driving path between
  them.
```

---

```text
FEATURE: EMERGENCY ASSISTANCE

PROBLEM
  Something goes wrong in a city you do not know and you have
  no idea where the nearest hospital is or what number to call.

USER DOES
  Taps "Emergency". Sees nearby hospitals and police stations
  sorted by distance, plus emergency numbers. Taps to call.

APP DOES
  Gets GPS position, asks Overpass for hospitals and police
  within a radius, calculates distance to each, sorts, and
  displays. Emergency numbers come from the database so they
  are available even if Overpass fails.

DATA FLOW
  Phone GPS ──your position──▶ Flutter
  Flutter ──"hospitals within 5km of here?"──▶ Overpass
  Flutter ◀──list of places with coordinates────┘
  Supabase ──emergency phone numbers──▶ Flutter

SERVICES
  Overpass API (free, no key). Phone's own dialer for calls.

DATABASE
  `emergency_contacts`     helpline numbers
  `last_known_location`    fallback position when GPS fails

RESULT
  A sorted list of nearby help, and one-tap dialling.
```

---

```text
FEATURE: RECOMMENDATIONS

PROBLEM
  You do not know what is worth seeing in a city you have
  never been to.

USER DOES
  Browses a list of places for their destination. Filters by
  category, price, rating. Taps one to add it to a day.

APP DOES
  Queries the hand-seeded `recommendations` table for rows
  matching the destination, sorts them, applies filters, and
  on tap writes a new `itinerary_items` row.

DATA FLOW
  Flutter ──"places in Bangalore, rating high to low"──▶ Supabase
  Flutter ◀──matching rows──────────────────────────────┘
       │
       └── user taps one ──▶ writes to `itinerary_items`

SERVICES
  Supabase only. This is a database query, not an engine.

DATABASE
  `recommendations`  reads (team-seeded by hand)
  `itinerary_items`  writes (when the user adds one)

RESULT
  A browsable list, and a one-tap path from "that looks good"
  to "it is on my Day 2".
```

---

# PART 6 — THE SYSTEM AS LAYERS

```text
                        ┌──────────────┐
                        │     USER     │
                        └──────┬───────┘
                               │  taps, types
                               ▼
                    ┌──────────────────────┐
                    │    FLUTTER APP       │
                    │  (running on phone)  │
                    │                      │
                    │  screens · logic ·   │
                    │  state (Provider)    │
                    └──┬────┬────┬────┬────┘
                       │    │    │    │
        ┌──────────────┘    │    │    └──────────────┐
        │            ┌──────┘    └──────┐            │
        ▼            ▼                  ▼            ▼
   ┌─────────┐  ┌─────────┐      ┌──────────┐  ┌──────────┐
   │  HIVE   │  │SUPABASE │      │   OSRM   │  │ OVERPASS │
   │(on the  │  │(internet)│     │(internet)│  │(internet)│
   │ phone)  │  └────┬────┘      └──────────┘  └──────────┘
   └─────────┘       │
                     ▼
              ┌─────────────┐         ┌──────────────────┐
              │ PostgreSQL  │         │  OpenStreetMap   │
              │  + Auth     │         │  (tile images)   │
              │  + RLS      │         │        ▲         │
              └─────────────┘         └────────┼─────────┘
                                               │
                                    flutter_map fetches these
                                    directly as you pan/zoom
```

## Every arrow, explained

**User → Flutter**
*Why:* somebody has to press things. *Sends:* taps, typed text. *Returns:* screens.

**Flutter → Supabase**
*Why:* the phone forgets everything when the app closes; the database does not. *Sends:* "save this trip", "give me Day 1's stops", "here are these login details". *Returns:* saved rows with IDs, requested rows, or an error.

**Supabase → PostgreSQL**
*Why:* Supabase is a friendly wrapper around a real database. Postgres is the thing actually storing rows on a disk. *Sends:* the query. *Returns:* rows. You never talk to Postgres directly — always through Supabase.

**Flutter → Hive**
*Why:* so the trip survives losing signal. *Sends:* a copy of the trip data to keep locally. *Returns:* that copy, later, with no internet needed.

**Flutter → OSRM**
*Why:* nothing else in the stack knows how roads connect. *Sends:* two or more coordinate pairs. *Returns:* the path along real roads, plus distance and duration.

**Flutter → Overpass**
*Why:* to find hospitals and police stations near a position. *Sends:* "amenity=hospital within 5km of these coordinates". *Returns:* matching OpenStreetMap entries with names and coordinates.

**flutter_map → OpenStreetMap**
*Why:* the map has to look like something. *Sends:* which tile squares are needed for this zoom and position. *Returns:* image squares.

**Phone GPS → Flutter**
*Why:* "nearby hospitals" needs to know what "nearby" means. *Sends:* nothing — Flutter asks the operating system. *Returns:* latitude, longitude, and an accuracy estimate.

## The one arrow that does not exist

```text
   Supabase  ──✗──▶  OSRM
   Supabase  ──✗──▶  Overpass
```

**Your database never talks to any external service.** Everything goes through Flutter, on the phone. Supabase is passive — it holds rows and answers questions. It never reaches out to anything on its own.

This matters for a reason you will feel later: **when the phone loses internet, everything stops at once.** There is no server quietly continuing to work on your behalf. That single fact is why offline mode has to be designed deliberately rather than assumed, and it is also the reason the "watchdog" idea from earlier would need something running server-side that does not currently exist.

---

# PART 7 — THE DATABASE, USING THE REAL TRIP

Forget tables for a second. The structure is just ownership, all the way down:

```text
   Vishwa  owns  a trip
                   │
                   ├── which has  days (calculated, not stored)
                   │                │
                   │                └── each with  stops
                   │
                   └── which has  a budget
                                    │
                                    └── against which  expenses land
```

## The real data

```text
┌─ profiles ─────────────────────────────────────────┐
│ id: u-001                                          │
│ full_name: Vishwa Thangapandiyan                   │
│ default_currency: INR                              │
└────────────────────────────────────────────────────┘
                     │  "u-001 made..."
                     ▼
┌─ trips ────────────────────────────────────────────┐
│ id: t-777                                          │
│ user_id: u-001    ◀── belongs to Vishwa            │
│ destination: Bangalore                             │
│ start_date: 2026-11-20                             │
│ end_date: 2026-11-23                               │
└────────────────────────────────────────────────────┘
          │                              │
          │                              │
          ▼                              ▼
┌─ itinerary_items ──────────┐  ┌─ budgets ──────────────────┐
│ id: i-01                   │  │ trip_id: t-777             │
│ trip_id: t-777  ◀── this   │  │ category: food             │
│ day_number: 1       trip   │  │ allocated_amount: 5000     │
│ title: Cubbon Park         │  ├────────────────────────────┤
│ order_index: 0             │  │ trip_id: t-777             │
├────────────────────────────┤  │ category: transport        │
│ id: i-02                   │  │ allocated_amount: 4000     │
│ trip_id: t-777             │  └────────────────────────────┘
│ day_number: 1                             │
│ title: Bangalore Palace                   │  compared against
│ order_index: 1                            ▼
└────────────────────────────┘  ┌─ expenses ─────────────────┐
                                │ trip_id: t-777             │
                                │ category: food             │
                                │ amount: 450                │
                                │ description: breakfast     │
                                └────────────────────────────┘
```

## What the IDs actually mean

A **foreign key** sounds technical and means something simple: a field holding someone else's ID, so the two rows know they are connected.

| Field | In plain English |
| --- | --- |
| `trips.user_id = u-001` | "This trip belongs to Vishwa." |
| `itinerary_items.trip_id = t-777` | "This stop belongs to the Bangalore trip." |
| `budgets.trip_id = t-777` | "This allocation belongs to the Bangalore trip." |
| `expenses.trip_id = t-777` | "This spend belongs to the Bangalore trip." |

Follow the chain upward from any expense and you land on Vishwa. That chain is what lets the database answer "show me only this user's stuff" without every table needing its own `user_id`.

## Why each table exists

| Table | Why it cannot be merged into another |
| --- | --- |
| `profiles` | Auth stores login credentials; this stores app preferences. Different concerns, different owners. |
| `trips` | One row per journey. The anchor everything else hangs from. |
| `itinerary_items` | Many stops per trip, so they cannot live *inside* the trip row. Separate rows means you can edit, delete, and reorder one without touching the others. |
| `budgets` | What you *planned* to spend, per category. |
| `expenses` | What you *actually* spent. Kept separate from `budgets` on purpose — plan and reality are different things, and you need both to compare them. |
| `recommendations` | Reference data, shared across all users, not owned by anyone. |
| `emergency_contacts` | Same — shared reference data. |
| `last_known_location` | One row per user, overwritten each time. History is not needed; only the most recent matters. |

## Days are not a table

Worth flagging because it surprises people. There is no `days` table. `itinerary_items` has a `day_number` column, and the day headings on screen are calculated from the trip's start and end dates.

```text
   start 20 Nov, end 23 Nov  →  Flutter works out: 4 days
                             →  draws 4 headings
                             →  puts each item under its day_number
```

If you stored days as rows, changing the trip's end date would mean going and fixing all the day rows too. Calculating instead means the days are always correct by definition.

## Row Level Security, briefly

**RLS** is a rule inside the database itself: *a user can only see rows that belong to them.*

Without it, the app would have to remember to filter by user on every single query — and the one place someone forgets, every user can read everyone else's trips. With it, the database refuses to hand over other people's rows regardless of what the app asks for. It is a lock on the vault rather than a policy about who is allowed to walk in.

---

# PART 8 — OFFLINE MODE

## The two storage places

```text
   ☁️  SUPABASE (cloud)            📱  HIVE (on the phone)
   ────────────────────           ──────────────────────
   The real, permanent copy       A photocopy taken at a
                                  moment in time

   Every device sees the same     Only this phone sees it
   thing

   Needs internet                 Needs nothing

   Always current                 As current as whenever
                                  you last downloaded
```

## The scenario, step by step

```text
   ─── Before the trip, at home on wifi ───

   User opens the Bangalore trip, taps "Download for offline"
                        │
                        ▼
   Flutter fetches from Supabase:
     • the trip row
     • all itinerary items for all 4 days
     • the destination's guide text
     • one static map image of Bangalore
                        │
                        ▼
   Flutter writes all of it into Hive, with a timestamp
                        │
                        ▼
   Screen shows "Downloaded ✓"


   ─── On the train, signal gone ───

   User opens the app
                        │
                        ▼
   Flutter tries Supabase ────✗ fails, no connection
                        │
                        ▼
   Flutter checks Hive ──────✓ found it
                        │
                        ▼
   Banner appears: "Offline — showing saved data"
   Itinerary loads normally
```

## What survives, and what does not

```text
   ✅ WORKS OFFLINE                  ❌ DOES NOT WORK OFFLINE
   ────────────────                  ────────────────────────
   Reading the itinerary             Panning around a live map
   Reading guide text                Getting a fresh route (OSRM)
   Seeing the static map image       Finding nearby hospitals
   Viewing your budget numbers         (Overpass needs internet)
   Emergency helpline numbers        Recommendations feed
   Calling those numbers*            Anything not downloaded first
                                     Syncing changes to the cloud
```

*Calling works because phone calls use the cellular voice network, which is separate from mobile data and reaches further. You can often call when you cannot browse. This is why one-tap dialling is genuinely valuable and not just convenient.

## The honest limitation

The offline map is **one static image**, not a real map you can pan and zoom. Caching a real, pannable offline map means downloading thousands of tile images per city, and that is a substantial engineering project on its own.

This is a deliberate, defensible scoping decision — not a bug — but it should be described accurately. "Offline access to your trip details and a destination overview" is true. "Offline maps" implies something the app does not do.

## Design decisions still open

⚠️ **What happens if the user edits something while offline?** Not decided. Options range from "block editing offline" (simplest) to "queue changes and sync when the connection returns" (much harder, and it raises the question of what happens when two devices edited the same thing). This needs deciding before offline gets built.

⚠️ **When does cached data expire?** Not decided. A trip downloaded three weeks ago may be stale.

---

# PART 9 — EMERGENCY FEATURES

## What Overpass actually is

Say this out loud once: **Overpass is a search box for OpenStreetMap data. It has no connection to any emergency service.**

It does not dispatch anyone. It does not know whether a hospital is open, has beds, or still exists. It knows that someone, at some point, marked a building on the map with the tag `amenity=hospital`. That is the entirety of what it offers.

```text
   Overpass IS                     Overpass IS NOT
   ───────────                     ───────────────
   A query tool over map data      An emergency service
   Free, no key needed             Verified or guaranteed
   Community-maintained            Real-time or authoritative
```

Two practical consequences: entries can be missing, outdated, or unnamed, and the app must therefore always show official helpline numbers regardless of what Overpass returns.

## The scenario

```text
   User is in Bangalore, something is wrong, taps "Emergency"
                              │
                              ▼
   Flutter asks the phone's OS for GPS
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
        Position found                  GPS unavailable
        12.9716, 77.5946                (denied / indoors / no signal)
              │                               │
              │                               ▼
              │                     Falls back to last known
              │                     position from Hive
              │                               │
              │                     Shows: "Using your last known
              │                     location from 2 hours ago —
              │                     this list may be outdated"
              │                               │
              └───────────────┬───────────────┘
                              ▼
   Flutter → Overpass: "hospitals and police within 5km of here"
                              │
                              ▼
   Overpass returns ~15 entries with names and coordinates
                              │
                              ▼
   Flutter calculates straight-line distance to each,
   sorts nearest first
                              │
                              ▼
   Flutter → Supabase: emergency helpline numbers
                              │
                              ▼
   ┌────────────────────────────────────────┐
   │  🚨 EMERGENCY                          │
   │                                        │
   │  Not a dispatch service. In a real     │
   │  emergency, call 112 directly.         │
   │                                        │
   │  [ 📞 112 ]  [ 📞 100 ]  [ 📞 108 ]    │
   │                                        │
   │  NEARBY                                │
   │  Bowring Hospital        0.8 km  📞   │
   │  Cubbon Park Police      1.2 km  📞   │
   │  Vani Vilas Hospital     1.9 km  📞   │
   └────────────────────────────────────────┘
```

## Why helplines come from the database, not Overpass

Because they must **never** fail to appear. Overpass can be slow, rate-limited, or down. GPS can be unavailable. If every one of those fails, the screen must still show 112. Storing them in your own database — and caching them in Hive — means they survive everything short of the phone being off.

## The safety framing

The disclaimer is not decoration. The app helps you *find* things; it does not summon anyone. Someone in a genuine emergency should be calling, not browsing a list. Making that the most prominent element on the screen — bigger than the hospital list — is the right design and the honest one.

---

# PART 10 — LOCATION TRACKING

## Where location comes from

```text
   🛰️  GPS satellites overhead
              │
              ▼
   📱 Phone's GPS chip works out where it is
              │
              ▼
   ⚙️  Operating system (Android / iOS) receives it
              │
              │  ← the OS decides whether your app is allowed
              │    to have it, and asks the user
              ▼
   📦 geolocator  (a Flutter package that talks to the OS)
              │
              ▼
   🎯 Your Flutter code gets: latitude, longitude, accuracy
```

Your app never talks to a satellite. It asks the operating system, and the OS decides whether to answer. That permission gate is the whole story of what is and is not possible here.

## Foreground vs background

```text
   FOREGROUND TRACKING              BACKGROUND TRACKING
   ───────────────────              ───────────────────
   App is open, on screen           App is closed or minimised,
                                    phone possibly locked

   Location updates freely          Needs special OS permission
                                    and a persistent notification

   Works everywhere, no             Extra Play Store review;
   special permission beyond        must justify why you need it
   the normal location prompt

   ✅ CORE — needed for             ⚠️ STRETCH — genuinely
      emergency and maps               achievable in Flutter,
                                       but real engineering
```

**This is exactly why Flutter was chosen over the web version.** Background tracking is not possible in a web app on any platform — that was the deciding constraint. In Flutter it is possible, and it is still a substantial piece of work.

## Your questions

**Does it need to send to Supabase every second?**
No, and it should not. Every second means constant network use, drained battery, and a database full of near-identical rows. Sensible approaches send an update every few minutes, or only when the user has actually moved a meaningful distance. The specific policy is **not yet decided**.

**What happens if the app is minimised?**
Foreground tracking stops. Background tracking continues, if built and permitted.

**What happens if internet disappears?**
GPS still works — it is satellites, not internet. So the phone still knows where it is. What fails is *sending* that position anywhere. Positions can be queued locally in Hive and uploaded when connection returns. **Not yet designed.**

## Core versus stretch, clearly

```text
   ✅ CORE (required for the main features)
   ────────────────────────────────────────
   One-off position lookup for "nearby hospitals"
   One-off position lookup for "route from here"
   Caching the last known position as a fallback

   ⚠️ STRETCH (agreed as NOT blocking the main project)
   ────────────────────────────────────────────────────
   Trip Mode — a session that samples position while
     the app is open, tracks itinerary progress, and
     surfaces nearby suggestions
   Continuous background tracking with the app closed
   Watchdog alerts when someone stops checking in
   Sharing live location with family or friends
```

Everything in the stretch column was discussed and none of it is designed. The Life360-style vision is real and worth building — the sequencing decision already made is that the six core features work first, and this layers on top afterwards.

---

# PART 11 — THE COMPLETE PICTURE

```text
                          ┌─────────────┐
                          │    USER     │
                          └──────┬──────┘
                                 │ taps / types
                                 ▼
   ╔═════════════════════════════════════════════════════════╗
   ║                   FLUTTER APP (the phone)               ║
   ║                                                         ║
   ║   ┌───────────────────────────────────────────────┐     ║
   ║   │  SCREENS                                      │     ║
   ║   │  login · trips · itinerary · map · budget ·   │     ║
   ║   │  emergency · recommendations · profile        │     ║
   ║   └────────────────────┬──────────────────────────┘     ║
   ║                        │                                ║
   ║   ┌────────────────────▼──────────────────────────┐     ║
   ║   │  STATE (Provider)                             │     ║
   ║   │  holds what's loaded right now, tells screens │     ║
   ║   │  to redraw when it changes                    │     ║
   ║   └────────────────────┬──────────────────────────┘     ║
   ║                        │                                ║
   ║   ┌────────────────────▼──────────────────────────┐     ║
   ║   │  LOGIC                                        │     ║
   ║   │  validation · budget maths · distance sorting │     ║
   ║   │  · day calculation · online/offline decision  │     ║
   ║   └──┬────────┬───────────┬───────────┬────────┬──┘     ║
   ╚══════╪════════╪═══════════╪═══════════╪════════╪════════╝
          │        │           │           │        │
          ▼        ▼           ▼           ▼        ▼
     ┌────────┐ ┌──────┐  ┌────────┐ ┌────────┐ ┌──────┐
     │  HIVE  │ │ GPS  │  │SUPABASE│ │  OSRM  │ │OVER- │
     │ local  │ │ via  │  │        │ │        │ │ PASS │
     │ cache  │ │geolo-│  │        │ │routing │ │      │
     │        │ │cator │  │        │ │        │ │find  │
     │ 📱 no  │ │      │  │        │ │        │ │near- │
     │internet│ │🛰️ no │  │        │ │        │ │by    │
     │ needed │ │inter-│  │        │ │        │ │POIs  │
     │        │ │ net  │  │        │ │        │ │      │
     └────────┘ └──────┘  └───┬────┘ └────────┘ └──────┘
                              │
              ┌───────────────┴──────────────┐
              ▼                              ▼
     ┌─────────────────┐          ┌────────────────────┐
     │  SUPABASE AUTH  │          │    POSTGRESQL      │
     │  who you are    │          │  + RLS (you only   │
     │  sessions       │          │    see your rows)  │
     └─────────────────┘          │                    │
                                  │ profiles · trips · │
                                  │ itinerary_items ·  │
                                  │ budgets · expenses │
                                  │ recommendations ·  │
                                  │ emergency_contacts │
                                  └────────────────────┘

     ┌──────────────────────────────────────────────┐
     │  OPENSTREETMAP                               │
     │  tile images, fetched directly by            │
     │  flutter_map as the user pans and zooms      │
     └──────────────────────────────────────────────┘
```

## Reading it top to bottom

**The user** only ever touches Flutter. Everything else is invisible to them.

**Flutter** is the entire brain. Every decision — is this date valid, are we over budget, is there internet, which hospital is closest — happens here, on the phone. This is worth internalising: there is no server-side logic anywhere in this system.

**Provider** is the middle layer holding whatever is currently loaded, so when a new expense arrives, every screen showing budget numbers updates without being told individually.

**The five outward arrows** are the only ways the app reaches anything beyond itself. Two of them — Hive and GPS — need no internet. Three do.

**Supabase** is two things wearing one name: an authentication service and a Postgres database. RLS sits inside the database enforcing that you only ever get your own rows.

**OpenStreetMap** hangs off to the side because flutter_map fetches tiles on its own as you move around, rather than your code requesting them explicitly.

## The three sentences worth memorising

1. **Flutter does all the thinking.** Nothing else in this system makes decisions.
2. **Supabase remembers; Hive remembers offline.** Neither one thinks.
3. **OSRM, Overpass, and OpenStreetMap are outside services that answer one narrow question each** — how do I drive there, what is nearby, what does the map look like — and know nothing about your trip.

---

# PART 12 — A DAY IN THE LIFE

Vishwa, 20 November, Bangalore. Every step shows what he sees and what happens underneath.

---

**09:00 — Opens the app**

```text
   SEES     Trip list, "Bangalore · 20–23 Nov" at the top
   FLUTTER  Checks for a saved session, finds one
   CALLS    Supabase: "trips for this user"
   DATABASE Reads `trips` — RLS silently filters to his rows only
   MOVES    One trip row comes back
```

---

**09:03 — Opens the trip, sets a budget**

```text
   SEES     Four day headings: 20, 21, 22, 23 November — all empty
   FLUTTER  Calculated those four days from the two stored dates.
            Nothing was fetched to produce them.

   He enters ₹15,000 split: food 5,000 · transport 4,000 ·
   stay 4,000 · activities 2,000

   CALLS    Supabase: four inserts
   DATABASE Four rows into `budgets`, all tagged trip_id t-777
   MOVES    Confirmations back; the screen shows four full bars
```

---

**09:06 — Browses recommendations**

```text
   SEES     A list of Bangalore places, highest rated first
   FLUTTER  Reads the trip's destination, queries by it
   CALLS    Supabase: "recommendations where destination = Bangalore,
            order by rating desc"
   DATABASE Reads `recommendations` — rows Vishwa typed in by hand
   MOVES    ~12 places with names, ratings, price levels, coordinates

   ⚠️  Nothing is being computed. No engine, no model. This is a
       sorted database query over a hand-written list.
```

---

**09:08 — Adds two places to Day 1**

```text
   SEES     Taps "Add to trip" on Cubbon Park, picks Day 1.
            Same for Bangalore Palace.
   FLUTTER  Builds a row for each: trip_id, day_number 1, title,
            coordinates copied over from the recommendation
   CALLS    Supabase: two inserts
   DATABASE Two rows into `itinerary_items`, order_index 0 and 1
   MOVES    Day 1 now shows two stops

   ⚠️  He chose the day. Nothing decided it for him. Nothing checked
       whether these two places are near each other, or whether
       there is time to do both.
```

---

**09:12 — Opens the map**

```text
   SEES     Bangalore, two pins
   FLUTTER  Already has the coordinates from the previous step
   CALLS    OpenStreetMap — tile images for this area and zoom
   DATABASE None touched
   MOVES    Image squares in; Flutter draws pins on top from data
            it already had
```

---

**09:13 — Taps "Route"**

```text
   SEES     A line following actual roads. "4.2 km · 14 min"
   FLUTTER  Takes the two coordinate pairs
   CALLS    OSRM: "drive from 12.976,77.595 to 12.998,77.592"
   DATABASE None touched
   MOVES    A list of coordinates tracing the road, plus distance
            and duration. Flutter hands the path to flutter_map,
            which draws it.

   ⚠️  Nothing about this route is saved. Ask again tomorrow and
       it gets calculated fresh.
```

---

**09:20 — Downloads for offline**

```text
   SEES     "Downloaded ✓"
   FLUTTER  Fetches everything needed, writes it all into Hive
   CALLS    Supabase: trip, all items, guide text
   DATABASE Reads several tables; writes one row to `offline_packs`
            recording that this trip was downloaded
   MOVES    A full copy of the trip now lives on the phone
```

---

**12:30 — Lunch, logs an expense**

```text
   SEES     Types ₹450, category Food. Food bar moves; still green.
   FLUTTER  Inserts the expense, then immediately re-fetches ALL
            expenses for the trip and re-adds them from scratch
   CALLS    Supabase: one insert, then one read
   DATABASE One row into `expenses`; reads all of them back
   MOVES    Every expense row returns. Flutter sums by category:
            food ₹450 of ₹5,000 = 9%. No warning.
```

---

**19:45 — Third meal of the day, logs another**

```text
   SEES     Food bar turns amber. "You have used 92% of your food
            budget."
   FLUTTER  Same recalculation. Food total now ₹4,600 of ₹5,000.
            4600 ÷ 5000 = 0.92, which crosses the 0.9 line.
   CALLS    Supabase: insert, then read
   DATABASE `expenses` again
   MOVES    Same as before — the only difference is that the
            comparison now crosses a threshold, so a banner shows

   ⚠️  This is two lines of arithmetic on the phone. There is no
       notification service and nothing scheduled.
```

---

**21:00 — Feels unwell, taps Emergency**

```text
   SEES     Big 112 button, then hospitals sorted by distance
   FLUTTER  Asks the OS for GPS, gets 12.9716, 77.5946
   CALLS    Overpass: "hospitals and police within 5km of here"
            Supabase: emergency helpline numbers
   DATABASE Reads `emergency_contacts`
   MOVES    ~15 places from Overpass. Flutter calculates straight-line
            distance to each and sorts. Bowring Hospital, 0.8 km,
            comes first.

   ⚠️  Overpass returned OpenStreetMap entries, not verified medical
       facilities. It does not know whether Bowring is open right now.
```

---

**22:30 — On a bus out of the city, signal dies**

```text
   SEES     "Offline — showing saved data". His itinerary loads.
   FLUTTER  Tries Supabase, the request fails, falls through to Hive
   CALLS    Nothing external
   DATABASE None — Hive only, on the phone
   MOVES    The copy saved at 09:20 comes back

   ✅ Works: itinerary, guide text, static map image, helpline numbers
   ❌ Does not: live map, new routes, nearby hospitals, recommendations
```

---

# PART 13 — WHAT IS REAL VERSUS WHAT IS NOT

The most important section in this document. Nothing here is padded to look better.

## ✅ DECIDED AND DEFINED

Settled. Build against these.

- **Flutter + Dart** as the app, targeting Android first
- **Supabase** for authentication and database, free tier
- **PostgreSQL** underneath, with **Row Level Security** on every table
- **Provider** for state management
- **Hive** for offline storage on the phone
- **flutter_map + OpenStreetMap** for map display
- **OSRM** public server for routing
- **Overpass API** for finding nearby hospitals and police
- **geolocator** for GPS
- **The database schema** — all tables, columns, and relationships, agreed and frozen
- **The six features** and which of the three of you owns each
- **Recommendations use a plain database ranking, not machine learning**
- **Offline scope**: cached trip data, guide text, one static map image — explicitly not pannable offline maps

## 🔨 DEFINED BUT NOT BUILT

Designed on paper. No code exists for any of it.

- Every one of the six features — accounts, itinerary, budget, maps, emergency, recommendations
- The database has been designed but not created in a live Supabase project
- Offline download and fallback
- Every screen

**Nothing is implemented yet.** The repository scaffold that exists holds documentation and folder structure, not working code.

## ⚠️ STILL AN OPEN DESIGN DECISION

Discussed, not settled. Each of these needs a real decision before the relevant work starts.

**Itinerary generation** — does not exist and has never been designed. If you want it, it is new scope with genuine design questions behind it, not a small addition.

**Offline editing** — what happens if someone edits a trip with no connection? Block it, or queue changes and sync later? Undecided, and it must be settled before offline is built.

**Cache expiry** — how long before downloaded data is considered stale? Undecided.

**Trip Mode** — the "start trip, track progress, suggest things nearby" session concept. Discussed, never designed. Would touch itinerary, recommendations, and emergency simultaneously.

**Background location tracking** — agreed as a stretch goal. Achievable in Flutter, requires Play Store justification for the permission, and is real engineering rather than a plugin drop-in.

**Watchdog / check-in alerts** — would need something running server-side, which does not currently exist anywhere in the architecture.

**SMS emergency alerts to contacts** — discussed, not decided.

**Sharing location with family** — the Life360 direction. Aspiration, not design.

**Play Store listing** — costs $25 and needs a privacy policy. Optional.

**iOS support** — Flutter supports it, but building for iOS requires a Mac with Xcode. Unresolved.

## 🚩 Documents that are now out of date

Flagging plainly, because this will bite otherwise:

**The SRS, DFDs, ER diagram, and UML diagrams all describe a web application.** They were written before the Flutter decision. The database design inside them survives unchanged, but every reference to browsers, web hosting, and IndexedDB is now wrong. They need revising before submission, or they will contradict the thing you actually demo.

---

# PART 14 — THE TECHNOLOGIES

Now that the system makes sense, here is what each name means. Four questions each, nothing more.

---

**FLUTTER**
*What:* a toolkit for building phone apps, where one codebase produces both Android and iOS versions.
*Why:* one codebase instead of two, and unlike a web app it can access background location — the deciding factor.
*Without it:* you would write the app twice, in two languages, or lose background tracking.
*Talks to:* everything. It is the centre of the system.

**DART**
*What:* the programming language Flutter is written in.
*Why:* it is not optional — Flutter requires it.
*Without it:* no Flutter.
*Talks to:* nothing directly. It is the language everything else is expressed in.

**PROVIDER**
*What:* a way to hold data that several screens need, so they update together when it changes.
*Why:* without it, adding an expense on one screen leaves the budget screen showing old numbers until manually refreshed.
*Without it:* you would pass data down through every screen by hand, and screens would fall out of sync.
*Talks to:* your Flutter screens.

**HIVE**
*What:* a small database that lives on the phone.
*Why:* offline mode. Something has to hold the copy when the internet is gone.
*Without it:* the app would be a blank screen with no connection.
*Talks to:* Flutter only. Never the internet.

**FLUTTER_MAP**
*What:* the Flutter widget that displays a map and lets you place markers on it.
*Why:* something must actually draw the map on screen.
*Without it:* you would have coordinates and no way to show them.
*Talks to:* OpenStreetMap, for tile images.

**OPENSTREETMAP**
*What:* a free, community-built map of the world — both the underlying data and pre-rendered tile images.
*Why:* free with no API key and no billing account, unlike Google Maps.
*Without it:* the map would have no imagery, and Overpass would have no data to search.
*Talks to:* flutter_map (tiles) and Overpass (data).

**OSRM**
*What:* a routing engine. Give it two points; it computes the driving path along real roads.
*Why:* nothing else in the stack knows how roads connect. A straight line between two pins is not a route.
*Without it:* you could show pins but never a real path, distance, or travel time.
*Talks to:* Flutter, when asked.

**OVERPASS**
*What:* a search API over OpenStreetMap data. "Find things tagged hospital near here."
*Why:* it is how the emergency feature finds anything.
*Without it:* you would have to hand-type every hospital in every city into your own database.
*Talks to:* Flutter, when asked. It is not an emergency service.

**SUPABASE**
*What:* a hosted package of a Postgres database, authentication, and an automatic API over both.
*Why:* free tier, handles login securely so you do not have to, and removes the need to write a backend at all.
*Without it:* you would build and host your own server and write your own authentication — weeks of work, and the security is easy to get wrong.
*Talks to:* Flutter, and the Postgres database underneath it.

**POSTGRESQL**
*What:* the actual database storing your rows on disk.
*Why:* it is what Supabase runs. Mature, reliable, handles relationships between tables properly.
*Without it:* nothing would persist.
*Talks to:* Supabase. You never address it directly.

**SUPABASE AUTH**
*What:* the login system — signup, sign-in, Google sign-in, sessions, password hashing.
*Why:* authentication is genuinely easy to get wrong and dangerous when you do.
*Without it:* you would write password hashing and session management yourself.
*Talks to:* Flutter, and issues the tokens Flutter stores.

**ROW LEVEL SECURITY (RLS)**
*What:* rules inside the database saying which rows a user is allowed to see.
*Why:* it makes data separation impossible to forget. The database refuses, regardless of what the app asks.
*Without it:* one missed filter in one query exposes every user's data to every other user.
*Talks to:* nothing — it is a rule inside Postgres.

**GEOLOCATOR**
*What:* a Flutter package that asks the phone's operating system for GPS position.
*Why:* "nearby hospitals" and "route from here" both need to know where you are.
*Without it:* no location-aware features at all.
*Talks to:* the phone OS, which talks to the GPS chip.

**BACKGROUND SERVICES**
*What:* OS-level permission for an app to keep working while closed or minimised.
*Why:* the only way continuous tracking works with the phone in a pocket.
*Without it:* tracking stops the moment the app leaves the screen.
*Talks to:* the phone OS. **Stretch goal — not part of the core project.**

---

# PART 15 — FIVE LEVELS OF ZOOM

## Level 1 — Ten seconds

> A travel app that keeps your trip plan, your budget, your map, and emergency help in one place, and still works when your signal dies.

## Level 2 — One minute

> You sign in and create a trip with a destination and dates. You set a budget split across food, transport, stay, and activities. You build a day-by-day list of stops, either by typing them in or by tapping suggestions from a list. Those stops appear as pins on a map with routes between them. You download the trip before you leave so it works offline. During the trip you log expenses and the app warns you before you overspend. If something goes wrong, one screen shows nearby hospitals and police with one-tap dialling.

## Level 3 — Five minutes

> The app is a Flutter application on the phone. All logic runs there — nothing runs on a server. It talks to four outside things.
>
> **Supabase** is the permanent memory: a Postgres database holding users, trips, stops, budgets, expenses, and recommendations, with rules ensuring you only ever see your own rows. It also handles login.
>
> **OpenStreetMap** supplies the map imagery. **OSRM** computes driving routes between coordinates. **Overpass** searches OpenStreetMap data for nearby hospitals and police.
>
> **Hive** is a copy of your trip stored on the phone, so the app still works with no connection.
>
> The pattern is always the same: the user does something, Flutter validates it, Flutter sends it to Supabase, Supabase confirms, Flutter redraws. Anything involving maps or nearby places takes a detour through one of the three external services.

## Level 4 — Fifteen minutes

Everything in Level 3, plus:

> **Where things are calculated.** Budget totals are recalculated on the phone from every expense row, every time, because a stored total goes stale. Day headings are calculated from the trip's two dates, not stored. Distance to hospitals is calculated on the phone from coordinates Overpass returned.
>
> **What is stored versus fetched.** Trips, stops, budgets, and expenses are stored. Routes are never stored — always recalculated. Map tiles are never stored except as one static image in the offline pack. Nearby hospitals are never stored.
>
> **How offline works.** Downloading writes a full copy into Hive with a timestamp. When a Supabase request fails, Flutter falls through to Hive and shows an offline banner. Reading works; anything needing a live service does not.
>
> **How security works.** Supabase Auth issues a session token the app stores. RLS inside Postgres enforces that queries only ever return your own rows — so even a bug in the app cannot leak someone else's trip.
>
> **What is genuinely missing.** No itinerary generation. No connection between budget and itinerary. No server-side logic of any kind. No background tracking in the core scope.

## Level 5 — Engineer

Tables: `profiles`, `trips`, `itinerary_items`, `budgets`, `expenses`, `offline_packs`, `emergency_contacts`, `last_known_location`, `recommendations`. RLS on all of them — own-row policies via the user ID, parent-trip subquery policies for child tables, read-only for shared reference data.

Packages: `supabase_flutter`, `flutter_map`, `geolocator`, `hive`, `provider`.

External endpoints: OSRM public routing server, Overpass interpreter, OpenStreetMap tile servers.

Ownership (re-planned 14 Oct 2026): Vishwa on accounts, itinerary, maps & routing and recommendations; Sanjay on offline and emergency; Santhosh on budget. Canonical record: `docs/OWNERSHIP.md`.

**Do not start here.** If Level 5 makes sense but Level 3 does not, the model is memorised rather than understood.

---

# PART 16 — QUIZ

Answer these before rereading anything. Where you hesitate is where the model is thin.

1. A user creates a trip. Where does that information end up, and what is the sequence of hops to get there?

2. Does OpenStreetMap calculate the driving route between two stops? If not, what does it actually provide?

3. Why does OSRM need to exist at all, given you already have a map and two sets of coordinates?

4. The internet disappears. The user opens their itinerary and it loads. Where did it come from, and what put it there?

5. What is Hive doing, and why can it not simply be replaced by Supabase?

6. Someone asks what Supabase does. Answer in two sentences without using the word "backend".

7. Which component in this system makes decisions — validation, budget maths, whether to show a warning?

8. Where does GPS data originate, and what stands between the satellite and your Flutter code?

9. A user swaps a Day 1 stop for a different place. Walk through what happens — what gets written, what gets recalculated, what gets refetched.

10. Name three things in this project that are core and three that are stretch goals, and explain why the split falls where it does.

**Bonus — the one that matters most:**

11. A user gives the app their destination, dates, budget, and interests. Describe exactly what the app does with each of those four things. Which of them actually shape the trip, and which are just stored?

Answer them in chat and I will correct whatever is off.
