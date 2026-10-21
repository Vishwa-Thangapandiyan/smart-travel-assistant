# Appium UI tests

End-to-end tests that drive the real app on a real Android phone, the way a
person would: tap "New trip", type "Goa", pick dates, tap "Create trip", and
check what the screen shows. They complement the widget tests in `test/`,
which run without a phone.

They live outside the Flutter app: Appium and these Python files are test
tools only and add nothing to `pubspec.yaml` or the app itself.

## What they cover — 18 tests

| File | Checks |
|---|---|
| `test_launch.py` | the app opens on Trips with the demo trip; every tab opens its screen with SOS always there; the Account sheet says it is demo mode |
| `test_trips.py` | an empty New-trip form names each missing field; coming back before leaving is caught; a new trip saves, opens on Day 1, and is listed on Trips |
| `test_stops.py` | Day 1 lists its stops; a stop needs a name; a new stop is added; another day has its own stops; a stop can be deleted |
| `test_budget.py` | the balance shows left and spent; an expense needs a positive amount; a logged expense comes off the balance |
| `test_explore_and_help.py` | Explore lists places highest rated first; a category filter narrows the list; the Map shows Day 1's first stop; SOS lists the helplines and closes |

They run on **fake data** (no Supabase keys), so every run sees the same
demo Bangalore trip, needs no account, and changes nothing online. The app is
restarted before each test, which puts the demo data back.

## One-time setup

1. Node.js, Python 3 and [uv](https://docs.astral.sh/uv/), plus the Android
   SDK platform tools (`adb`).
2. Appium 3 and its Android driver:

   ```bash
   npm install -g appium@3
   appium driver install uiautomator2
   ```

3. A phone with **USB debugging** on, plugged in. Check with `adb devices`.
   The first run installs two Appium helper apps on the phone; on Oppo,
   OnePlus, Xiaomi and similar phones, tap **Install** on each prompt (or
   turn off *Verify apps over USB* in Developer options).

## Run them

```bash
# 1. Build and install the fake-data app (no --dart-define keys)
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 2. Start Appium in one terminal
ANDROID_HOME=~/Android/Sdk appium

# 3. Run the tests in another
cd appium
uv run --no-project --with-requirements requirements.txt pytest -v --junitxml=results.xml
```

Without uv: `pip install -r requirements.txt`, then `pytest -v`.

Leave the phone alone while the tests run (about 5 minutes); a notification
or another app coming to the front makes a test fail. When one fails, a
screenshot of the phone at that moment is saved in `appium/failures/`.

Installing the fake-data app replaces the real-data one on the phone; your
saved data stays. Run `flutter run` with the Supabase keys (see `RUN.md`)
afterwards to go back.

## How they find things

Flutter gives Android each label on screen as the element's accessibility
text, so `screens.py` finds buttons and text by what they say ("Log an
expense", "Save stop"), and text fields by their hint ("Amount", "Stop
name"). If a label in the app changes, the test that uses it needs the same
change.
