import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:smart_travel_assistant/theme/theme_provider.dart';

void main() {
  late Box<String> settings;

  // A fresh in-memory box for every test.
  setUp(() async => settings = await Hive.openBox<String>('settings_${DateTime.now().microsecondsSinceEpoch}', bytes: Uint8List(0)));

  test('follows the phone until the user picks', () {
    expect(ThemeProvider(settings).mode, ThemeMode.system);
  });

  test('a picked mode is kept for the next start', () async {
    await ThemeProvider(settings).setMode(ThemeMode.light);

    expect(ThemeProvider(settings).mode, ThemeMode.light);
  });

  test('an unknown saved value falls back to the phone', () async {
    await settings.put('theme', 'sepia');

    expect(ThemeProvider(settings).mode, ThemeMode.system);
  });
}
