# Running the app

There is no `.env` file in this project. Flutter doesn't read one, and we
decided not to add a package (like `flutter_dotenv`) just to simulate one
— see `pubspec.yaml`, the dependency list is fixed. Instead, the two
Supabase values get passed at build/run time with `--dart-define`, and
`lib/main.dart` reads them with `String.fromEnvironment`.

## The command

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
```

Replace both values with the real ones from the group chat (posted by
Vishwa after he creates the Supabase project — see his `PLANNER.md`,
Phase A).

Once the app shell is merged, the app can also run with fake data and no
Supabase at all (`--dart-define=USE_FAKE_DATA=true`) — see
`lib/services/README.md`. The app shell PR documents the exact command
here.

If you forget either `--dart-define`, the app throws a clear error on
startup instead of failing silently later — see the check at the top of
`main()` in `lib/main.dart`.

## Making this less annoying to retype

The command above is long. Two options, pick whichever you're comfortable
with:

- **Shell alias.** Add a line like this to your `~/.bashrc` or
  `~/.zshrc` (with your real values filled in), then just run
  `flutter run` as normal... actually, Flutter doesn't read shell env vars
  into `--dart-define` automatically, so this needs to be a full alias:

  ```bash
  alias flutter-run-travel='flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...'
  ```

- **VS Code launch config.** If you use VS Code's Flutter extension, add
  an entry to `.vscode/launch.json` with a `"toolArgs"` array containing
  the same two `--dart-define` flags, then use the Run/Debug button
  instead of the terminal. `.vscode/` is gitignored except
  `extensions.json`, so this file stays local to you — don't put real
  keys in anything that isn't gitignored.

Whichever you pick, **never commit the real values** — not in a script, a
committed `launch.json`, or anywhere else. The rules from `README.md` §6
still apply: the anon key is safe in a compiled app (Row Level Security is
what actually protects the data) but stays out of the repo anyway, on
principle and because the same habit protects whatever gets added to this
project later that genuinely is a secret.

## Building a release APK

Same idea, different command:

```bash
flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Nobody needs this until Sprint 6 (deploy). Documented here now so it's not
a surprise later.
