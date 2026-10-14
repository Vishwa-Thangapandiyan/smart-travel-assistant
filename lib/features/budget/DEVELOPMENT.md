# Budget development and standalone demo

Budget code lives in this feature folder and uses the existing shared models,
Supabase getter, trip service and Meridian theme. No additional packages or
schema changes are required. The existing app's Budget tab already registers
BudgetProvider and opens BudgetScreen.

## Run on Android

Run from the repository root with Flutter on PATH:

```bash
flutter pub get --enforce-lockfile
flutter run --target lib/features/budget/budget_demo.dart --dart-define=USE_FAKE_DATA=true
```

The standalone demo has a day/night toggle. The normal app uses its existing
navigation and theme. Demo budgets and expenses live in memory and reset when
the app restarts or the browser reloads. The Bangalore sample reproduces the
budget design's allocations and spending. Other trips start with no allocation.

## Build a browser demo for hosting

```bash
bash lib/features/budget/build_web_demo.sh
```

This creates a temporary Flutter web shell outside the checkout, with the same
locked dependencies. It prints the generated `build/web` directory. Host that
whole directory with any static HTTPS host. Flutter's renderer and bundled fonts
are included locally; this demo does not need Supabase or Google Fonts.
Rebuild after source changes. Nothing is deployed by this script.

## Checks

```bash
flutter analyze
flutter test
flutter build apk --debug --dart-define=USE_FAKE_DATA=true
```

The budget tests cover amount validation, exact 90% warnings, zero allocations,
editing/deleting expenses, separate trips, stale requests, failed saves and
refreshes, and the budget/expense forms.

## Real data integration

Run the normal app with the Supabase defines in RUN.md and sign in. BudgetStore
uses the existing `budgets` and `expenses` tables, scoped by `trip_id`; the existing
row-level security policies protect users' trip data. Budget allocations upsert
on `(trip_id, category)`. Spent totals are calculated from expense rows in whole
paise, never stored as another field. Live Supabase permissions and persistence
still need testing with the team's project and a signed-in account.

Amounts use INR to match the supplied budget design. Category allocations may be
zero; an expense must be positive, with at most two decimal places. Expenses can
be entered for any chosen calendar date from 2000–2100. The Today switch filters
the expense list only; category budgets and the main balance always cover the
whole trip. Descriptions are optional, matching the existing Expense model.

If a save cannot be confirmed, close the form and reload before retrying. This
avoids blindly resubmitting an expense after a possible network interruption.
Budget never reads or changes itinerary items. No automatic stop prices,
notifications, currency conversion or emergency functionality are added.
