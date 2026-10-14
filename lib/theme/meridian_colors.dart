// The Meridian palette, from design/tokens.json. Screens read it with
// Theme.of(context).extension<MeridianColors>()! — never write hex
// colours in feature code (AGENTS.md).

import 'package:flutter/material.dart';

@immutable
class MeridianColors extends ThemeExtension<MeridianColors> {
  final Color ground; // screen background
  final Color surface; // cards, rows, nav bar, sheets
  final Color ember; // icon circles, photo placeholders
  final Color line; // borders and dividers
  final Color ink; // main text
  final Color inkSoft; // secondary text
  final Color amber; // route, next stop, primary action
  final Color amberText; // amber used as text (darker by day for contrast)
  final Color onAmber; // text on amber
  final Color coral; // SOS and over budget only
  final Color onCoral;
  final Color green; // saved offline, done
  final Color key; // rare informational accents

  const MeridianColors({
    required this.ground,
    required this.surface,
    required this.ember,
    required this.line,
    required this.ink,
    required this.inkSoft,
    required this.amber,
    required this.amberText,
    required this.onAmber,
    required this.coral,
    required this.onCoral,
    required this.green,
    required this.key,
  });

  static const night = MeridianColors(
    ground: Color(0xFF0B0907),
    surface: Color(0xFF17120D),
    ember: Color(0xFF2B1A0C),
    line: Color(0x1FF7ECDC),
    ink: Color(0xFFF7ECDC),
    inkSoft: Color(0xA8F7ECDC),
    amber: Color(0xFFF39A2B),
    amberText: Color(0xFFF39A2B),
    onAmber: Color(0xFF1F1104),
    coral: Color(0xFFFF6B5B),
    onCoral: Color(0xFF2A0705),
    green: Color(0xFF8FD1A5),
    key: Color(0xFF9FB6D4),
  );

  static const day = MeridianColors(
    ground: Color(0xFFF5ECDD),
    surface: Color(0xFFFFFAF2),
    ember: Color(0xFFE6D8C2),
    line: Color(0xFFE6D8C2),
    ink: Color(0xFF1C140D),
    inkSoft: Color(0x9E1C140D),
    amber: Color(0xFFF39A2B),
    amberText: Color(0xFFB35A07),
    onAmber: Color(0xFF1F1104),
    coral: Color(0xFFB83228),
    onCoral: Color(0xFFFFFFFF),
    green: Color(0xFF2C7647),
    key: Color(0xFF3A6AA6),
  );

  @override
  MeridianColors copyWith({
    Color? ground,
    Color? surface,
    Color? ember,
    Color? line,
    Color? ink,
    Color? inkSoft,
    Color? amber,
    Color? amberText,
    Color? onAmber,
    Color? coral,
    Color? onCoral,
    Color? green,
    Color? key,
  }) {
    return MeridianColors(
      ground: ground ?? this.ground,
      surface: surface ?? this.surface,
      ember: ember ?? this.ember,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      amber: amber ?? this.amber,
      amberText: amberText ?? this.amberText,
      onAmber: onAmber ?? this.onAmber,
      coral: coral ?? this.coral,
      onCoral: onCoral ?? this.onCoral,
      green: green ?? this.green,
      key: key ?? this.key,
    );
  }

  // Night and day never blend in this app, so lerping just picks a side.
  @override
  MeridianColors lerp(MeridianColors? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
