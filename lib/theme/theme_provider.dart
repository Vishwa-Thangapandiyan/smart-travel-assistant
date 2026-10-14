// Owner: Vishwa. Day or Night: follows the phone unless the user picks one
// in the Account sheet. The choice is kept on the phone in the Hive box
// "settings", so it survives a restart and needs no account.

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  static const boxName = 'settings';
  static const _key = 'theme';

  final Box<String> _settings;
  ThemeMode _mode;

  // Saved as "system", "light" or "dark"; anything else means "system".
  ThemeProvider(this._settings) : _mode = ThemeMode.values.asNameMap()[_settings.get(_key)] ?? ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await _settings.put(_key, mode.name);
  }
}
