# DESIGN.md — Meridian app design

The visual design for the app. **Any UI work follows this file.** It is
written for people and for AI tools (Claude Code, Codex): every screen in
the app has a reference picture in `design/screens/`, exact values in
`design/tokens.json`, and a standalone HTML version in `design/artboards/`
you can open in a browser to inspect sizes and colours.

The public product name is **Meridian**. The full project title, Smart
Travel Planning Assistant and Budget Management System, stays in the
report and the footer of any about screen.

Source: the team's design canvas on claude.ai (private — ask Vishwa for
access). This file and `design/` are the copy everyone builds from; if
they ever disagree with the canvas, raise it rather than guessing.

## 1. Principles

1. **The route is the brand.** One amber line draws the day, the map and
   the next step. Amber means "this way" — the route, the next stop, and
   the main button on a screen. Nothing else is amber.
2. **Big numbers for now.** The next stop's time and the money left are
   the largest things on their screens.
3. **Now is inverted.** The current item flips to cream (night) or ink
   (day). Everything else stays quiet.
4. **Honest offline.** A saved trip says it's saved. A feature that needs
   signal says so. Never imply a pannable offline map.
5. **SOS is one tap.** Coral is reserved for SOS and over-budget. The SOS
   button is in the navigation bar on every main screen.

## 2. Modes

Night (dark) is the primary look; Day (light, cream paper) is the same app
for bright sunlight. Both must exist. Decided: the app follows the phone's
system setting, and the Account sheet has a Phone / Day / Night switch
that overrides it. The choice is kept on the phone (Hive box `settings`,
`lib/theme/theme_provider.dart`). Read colours from the theme, never test
for a mode yourself: the map's night tiles key off `Theme.of(context).brightness`.

## 3. Colour

Exact values: `design/tokens.json`. Use them through `ThemeData` /
`ColorScheme` in `lib/theme/`, never as hex literals in feature code.

| Role | Night | Day | Use |
| --- | --- | --- | --- |
| ground | `#0B0907` | `#F5ECDD` | Screen background |
| surface | `#17120D` | `#FFFAF2` | Cards, rows, nav bar, sheets |
| ember | `#2B1A0C` | — | Icon circles, photo placeholders |
| line | `rgba(247,236,220,0.08–0.18)` | `#E6D8C2` | Borders, dividers |
| ink | `#F7ECDC` | `#1C140D` | Main text |
| ink soft | ink at 60–66% | ink at 55–62% | Secondary text |
| amber (primary) | `#F39A2B` | `#F39A2B` fill / `#B35A07` text, `#D9780F` line | Route, next, primary button |
| on amber | `#1F1104` | `#1F1104` | Text on amber |
| coral (danger) | `#FF6B5B` | `#B83228` | SOS, over budget, alerts |
| green (ok) | `#8FD1A5` | `#2C7647` | Saved offline, done |
| key (info) | `#9FB6D4` | `#3A6AA6` | Rare informational accents |

Text on any background must reach 4.5:1 contrast (3:1 for 24 px and up).
Colours that must be told apart (done / next / later) also differ in
lightness, not hue alone.

## 4. Type

| Family | Use | Flutter |
| --- | --- | --- |
| **Manrope** | Everything in the interface: titles, body, buttons, big numbers | `fontFamily: 'Manrope'` |
| **JetBrains Mono** | Anything measured — times, money labels, distances, dates — and the day heading | `fontFamily: 'JetBrainsMono'` |

Both are free (SIL Open Font License). **Bundle them as font files**
under `assets/fonts/` and declare them in `pubspec.yaml`'s `flutter:
fonts:` section — do **not** add the `google_fonts` package (no new
dependencies, `AGENTS.md` rule 5).

| Style | Size / weight | Tracking | Example |
| --- | --- | --- | --- |
| now-number | 52–88 / 600–700 | −5 to −6% | `12:30`, `₹3,940`, `37` |
| title | 26 / 600 | −2.5% | Bangalore |
| heading | 18 / 600 | −1.5% | Bangalore Palace |
| body | 15 / 400 | 0 | Audio tour at the gate |
| small | 12 / 400 | 0 | Walk to the State Library |
| mono-heading | 20 / 500 mono | −2% | Saturday, 21 Nov |
| mono-data | 11–12 / 500 mono, caps where a label | +4–8% for caps | NEXT · 7.1 KM · 12 MIN |

Numbers use tabular figures so they don't jump while they change.

Sizes were stepped down on 14 Oct 2026 after checking on a real phone —
the pictures in `design/screens/` use the earlier, larger scale.

## 5. Space, shape, touch

- Spacing scale: 4, 8, 12, 16, 20, 24, 32. Screen side padding 20.
- Radius: 12 small controls, 16–18 rows, 24 cards, 28–30 sheets, full
  pill for buttons, chips and the nav bar.
- Touch targets at least 48 × 48 dp (Android). Icon-only buttons get a
  `Semantics` / `tooltip` label.

## 6. Components

- **Primary button** — amber pill, 46–54 tall, dark text. One per screen.
- **Secondary button** — outline pill (line colour), ink text.
- **Text button** — amber text, no border (e.g. "From suggestions").
- **Icon circle** — 52 round, ember fill, amber icon, soft amber glow
  (night only).
- **Navigation bar** — floating pill, 68 tall, 16 from the screen edges:
  Days, Map, Budget, Explore as round 48 icon buttons (active one filled
  cream/ink), then a coral **SOS** pill. Labels via semantics.
- **Day switcher** — pill track with one segment per day (`Fri 20`),
  selected segment inverted.
- **Stop rail** — vertical line down the day: amber up to the next stop,
  faint after it. Done stops collapse into one line ("Done · MTR 08:00 ·
  Lalbagh 09:30").
- **Now card** — the next stop: inverted card with the huge time, `IN 40
  MIN / 7.1 KM`, name, note, *Route there* (primary) and an edit icon.
- **Later row** — name + note on the left, mono time on the right.
- **Category row** (budget) — rounded row, name and `spent of allocated`
  left, money left in mono on the right. Over 90% → coral-tinted row.
- **Chip** — small pill: *Saved offline* (green), *Transport 93%* (coral),
  neutral outline for facts.
- **Map marker** — numbered circle; done = filled dark, next = amber with
  a glow ring, later = outlined.
- **Route line on the map** — amber 4.5 px with a dark (night) or light
  (day) 9 px halo; travelled-so-far solid, later legs dotted.

## 7. Screens

Picture → `design/screens/<file>.png`; HTML → `design/artboards/<file>.html`.

| Screen | File | Feature (owner) |
| --- | --- | --- |
| Design system board | `design-system` | everyone |
| Sign in | `night-01-sign-in` | Accounts (Vishwa) |
| Trips | `night-02-trips` | Itinerary (Vishwa) |
| Day | `night-03-day`, `day-03-day` | Itinerary (Vishwa) |
| Map — saved offline | `night-04-map-saved-offline`, `day-04-map` | Maps (Vishwa) + Offline state (Sanjay) |
| Budget | `night-05-budget`, `day-05-budget` | Budget (Santhosh) |
| Explore | `night-06-explore` | Recommendations (Vishwa) |
| SOS | `night-07-sos` | Emergency (Sanjay) |
| Home-screen widgets | `home-screen-widgets` | **Not in scope** — needs a widget package; kept for later |
| Motion | `motion` | everyone |

Screens without a picture yet (add-stop form, expense form, offline
download state, empty states) follow the same components and rules.

What each screen must get right:

- **Sign in** — a real form: email, password (show toggle), forgot
  password, *Sign in* (primary), *Continue with Google*, *Create an
  account*. Errors appear inline under the field, in plain words.
- **Trips** — globe with destination chips, the upcoming trip as an
  inverted card with "37 days to go", other trips as rows, `+` to create.
- **Day** — back to the trip, *Saved offline* chip, day switcher, mono day
  heading with stop count and total distance, the stop rail, the now card,
  later rows, *Add a stop* + *From suggestions*. Itinerary is built by
  hand — nothing suggests it was generated.
- **Map** — *Live map / Saved map* switch. With no signal the saved map
  shows with "No signal — showing the map you saved. New routes need
  signal." Next-stop card at the bottom. OpenStreetMap attribution always
  visible (licence condition).
- **Budget** — money left as the hero number, spent bar, category rows
  (alert row first when over 90%), the note "Stops in your plan don't
  carry prices — only what you log counts here", *Log an expense*.
- **Explore** — destination as a big mono headline, filter chips, "Highest
  rated first" (it's a database ranking — never call it AI or smart
  picks), cards with a photo and a `+` to add to a day.
- **SOS** — coral header, big *Call emergency 112*, helplines 100 / 108 /
  101 ("These numbers work without data"), nearest hospitals and police
  with route and call buttons, the stale-location warning, and the
  disclaimer: "Meridian is not an emergency dispatch service. In a
  life-threatening emergency, also call local services directly."

## 8. Maps

- Tiles: standard OpenStreetMap tiles through `flutter_map` (the agreed
  stack). Night look = the same tiles darkened in the app with a
  `ColorFiltered` matrix (invert + warm tint) — no extra map provider.
- Route geometry from OSRM (`routing_service.dart`).
- Attribution "© OpenStreetMap contributors" visible on every map.
- The offline map is one saved image, not pannable — label it as saved.

## 9. Motion

Ease `cubic-bezier(0.22, 0.61, 0.36, 1)` (Flutter: `Cubic(0.22, 0.61,
0.36, 1)`); quick 180 ms, standard 320 ms, expressive 600 ms. Only four
moments move:

1. **Rolling numbers** (320 ms) — countdowns and money left roll one
   digit at a time.
2. **The route draws** (600 ms) — opening a day, the rail draws down to
   the next stop.
3. **Next stop flips** (280 ms) — marking a stop done dims it and inverts
   the next row. Only the user marks stops done; nothing tracks them.
4. **SOS opens** (350 ms) — coral grows out of the button; helplines show
   first, nearby places load after.

With reduced motion on (`MediaQuery.disableAnimations`), every moment is
an instant swap or short fade.

## 10. Content rules

- Example data in the pictures (Bangalore, 20–23 Nov, ₹15,000, the five
  stops, 7.1 km / 14.7 km from OSRM) is demo data, not product claims.
- Never show invented ratings, reviews, user counts or store badges in the
  shipped app.
- Photos in Explore are placeholders in the pictures; real images need a
  source the team agrees on.
