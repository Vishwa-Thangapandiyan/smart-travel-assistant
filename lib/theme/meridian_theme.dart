// Builds the app's ThemeData from the Meridian palette. One function for
// both modes, so night and day can never drift apart. See DESIGN.md.

import 'package:flutter/material.dart';

import 'meridian_colors.dart';

const _sans = 'Manrope';
const _mono = 'JetBrainsMono';

/// Text styles the Material text theme has no slot for. Colours come from
/// the surrounding DefaultTextStyle, so these work in both modes.
class MeridianText {
  MeridianText._();

  /// The huge "now" numbers: next stop time, money left, days to go.
  static const nowNumber = TextStyle(
    fontFamily: _sans,
    fontSize: 52,
    fontWeight: FontWeight.w600,
    letterSpacing: -3.5,
    height: 0.9,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Times, distances and money labels.
  static const monoData = TextStyle(
    fontFamily: _mono,
    // JetBrains Mono has no ₹ glyph; Manrope draws it instead.
    fontFamilyFallback: [_sans],
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  /// A place's name over its photo, big, like a poster.
  static const monoDisplay = TextStyle(
    fontFamily: _mono,
    fontFamilyFallback: [_sans],
    fontSize: 40,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.6,
    height: 1.05,
  );

  /// The day heading, e.g. "Saturday, 21 Nov".
  static const monoHeading = TextStyle(
    fontFamily: _mono,
    fontFamilyFallback: [_sans],
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.4,
  );
}

ThemeData meridianTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? MeridianColors.night : MeridianColors.day;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.amber,
    onPrimary: c.onAmber,
    secondary: c.key,
    onSecondary: c.ground,
    error: c.coral,
    onError: c.onCoral,
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.inkSoft,
    outline: c.line,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.ground,
    fontFamily: _sans,
  );

  const pill = StadiumBorder();
  const buttonSize = Size(48, 52);

  return base.copyWith(
    extensions: [c],
    dividerColor: c.line,
    textTheme: base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.65, color: c.ink),
      titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: c.ink),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.5, color: c.ink),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 14, color: c.ink),
      bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 12, color: c.inkSoft),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.amber,
        foregroundColor: c.onAmber,
        minimumSize: buttonSize,
        shape: pill,
        textStyle: const TextStyle(fontFamily: _sans, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        minimumSize: buttonSize,
        shape: pill,
        side: BorderSide(color: c.line),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.amberText, minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.amber, width: 1.5)),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
