// Standalone fake-data entry point for reviewing Budget before integration.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dev/app_config.dart';
import '../../theme/meridian_theme.dart';
import '../accounts/accounts_provider.dart';
import 'budget_provider.dart';
import 'budget_screen.dart';

void main() {
  if (!useFakeData) {
    throw StateError('The standalone budget demo requires USE_FAKE_DATA=true.');
  }
  runApp(const BudgetDemoApp());
}

class BudgetDemoApp extends StatefulWidget {
  const BudgetDemoApp({super.key});
  @override
  State<BudgetDemoApp> createState() => _BudgetDemoAppState();
}

class _BudgetDemoAppState extends State<BudgetDemoApp> {
  bool _dark = true;
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AccountsProvider()),
          ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ],
        child: MaterialApp(
          title: 'Meridian · Budget demo',
          debugShowCheckedModeBanner: false,
          theme: meridianTheme(Brightness.light),
          darkTheme: meridianTheme(Brightness.dark),
          themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
          home: Scaffold(
            appBar:
                AppBar(title: const Text('Meridian · Budget demo'), actions: [
              IconButton(
                  tooltip: 'Switch day/night theme',
                  onPressed: () => setState(() => _dark = !_dark),
                  icon: Icon(_dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined)),
            ]),
            body: const BudgetScreen(),
          ),
        ),
      );
}
