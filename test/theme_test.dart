import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_assistant/theme/meridian_colors.dart';
import 'package:smart_travel_assistant/theme/meridian_theme.dart';

// Expected values are copied from design/tokens.json, not from the code.
void main() {
  test('night theme is dark, on the night ground, with amber as primary', () {
    final theme = meridianTheme(Brightness.dark);

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF0B0907));
    expect(theme.colorScheme.primary, const Color(0xFFF39A2B));
    expect(theme.colorScheme.onSurface, const Color(0xFFF7ECDC));
  });

  test('day theme is light, on cream paper, with dark ink', () {
    final theme = meridianTheme(Brightness.light);

    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF5ECDD));
    expect(theme.colorScheme.onSurface, const Color(0xFF1C140D));
  });

  test('coral is the danger colour in both modes', () {
    expect(meridianTheme(Brightness.dark).colorScheme.error, const Color(0xFFFF6B5B));
    expect(meridianTheme(Brightness.light).colorScheme.error, const Color(0xFFB83228));
  });

  test('interface text is Manrope', () {
    final theme = meridianTheme(Brightness.dark);

    expect(theme.textTheme.bodyMedium!.fontFamily, 'Manrope');
    expect(theme.textTheme.titleLarge!.fontFamily, 'Manrope');
  });

  test('screens can read the full Meridian palette from the theme', () {
    final colors = meridianTheme(Brightness.dark).extension<MeridianColors>();

    expect(colors, isNotNull);
    expect(colors!.ember, const Color(0xFF2B1A0C));
    expect(colors.green, const Color(0xFF8FD1A5));
  });
}
