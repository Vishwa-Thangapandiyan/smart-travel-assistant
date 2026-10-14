# lib/theme/ — the app's look in code

Owner: Vishwa. Built from `design/tokens.json`; the rules behind it are
in [`DESIGN.md`](../../DESIGN.md).

## How to use it in a screen

```dart
final colors = Theme.of(context).extension<MeridianColors>()!;
final text = Theme.of(context).textTheme;

Text('Bangalore Palace', style: text.titleLarge);          // Manrope
Text('12:30', style: MeridianText.nowNumber);              // the big "now" number
Text('7.1 KM · 12 MIN', style: MeridianText.monoData.copyWith(color: colors.amberText));
FilledButton(onPressed: route, child: const Text('Route there'));   // amber pill
```

- **Never** write a hex colour or a font name in feature code. If a value
  you need isn't here, ask Vishwa to add it rather than inventing one.
- `FilledButton` is the one primary (amber) action on a screen;
  `OutlinedButton` for secondary; `TextButton` for small amber links.
- Amber means "this way" — the route, the next stop, the main button.
  Coral (`colors.coral`) is only for SOS and over-budget.

## Why it's built this way

- **One function, both modes.** `meridianTheme(Brightness)` builds night
  and day from the same code, so they can't drift apart. Night is the
  default; whether the app follows the phone's day/night setting is not
  decided yet (`DESIGN.md` §2).
- **A theme extension for the palette.** Material's `ColorScheme` has no
  slot for colours like ember or "saved" green, so the full palette rides
  along as `MeridianColors` and is read from the theme like anything else.
- **Fonts are bundled files**, declared in `pubspec.yaml`, not the
  `google_fonts` package — no new dependency, and text renders offline.
- **JetBrains Mono has no ₹ sign**, so the mono styles fall back to
  Manrope for that one character.
