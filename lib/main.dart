// Entry point. Starts Supabase (unless running on fake data) and Hive,
// registers
// every feature's Provider once, and applies the Meridian theme. Feature
// owners fill in their own provider and screen files — this file should
// rarely need to change.
//
// Supabase config comes from --dart-define, not a .env file (RUN.md).

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dev/app_config.dart';
import 'features/accounts/accounts_provider.dart';
import 'features/accounts/auth_gate.dart';
import 'features/budget/budget_provider.dart';
import 'features/emergency/emergency_provider.dart';
import 'features/itinerary/itinerary_provider.dart';
import 'features/maps/maps_provider.dart';
import 'features/offline/offline_provider.dart';
import 'features/recommendations/recommendations_provider.dart';
import 'theme/meridian_theme.dart';
import 'theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!useFakeData) {
    if (supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL is set but SUPABASE_ANON_KEY is missing — see RUN.md.',
      );
    }
    // A real key is only letters, digits, dots, dashes and underscores.
    // Copying it from a screen that masks secrets gives "•" instead, which
    // otherwise fails much later as a confusing "couldn't reach" error.
    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(supabaseAnonKey)) {
      throw StateError(
        'SUPABASE_ANON_KEY has characters a key can\'t have (often "•" from a masked copy). '
        'Copy it again from Supabase → Project Settings → API — see RUN.md.',
      );
    }
    // Supabase renamed the anon key to the "publishable" key; it is the
    // same public value, so the --dart-define name stays as it is.
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  }

  // Hive is started once, here, for everyone: the theme choice now, and
  // downloaded trips (Offline) later in boxes of their own.
  await Hive.initFlutter();
  final settings = await Hive.openBox<String>(ThemeProvider.boxName);

  runApp(MeridianApp(settings: settings));
}

class MeridianApp extends StatelessWidget {
  final Box<String> settings;

  const MeridianApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(settings)),
        ChangeNotifierProvider(create: (_) => AccountsProvider()),
        ChangeNotifierProvider(create: (_) => ItineraryProvider()),
        ChangeNotifierProvider(create: (_) => MapsProvider()),
        ChangeNotifierProvider(create: (_) => OfflineProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationsProvider()),
      ],
      // Builder: the theme mode has to be read below the providers above.
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'Meridian',
          debugShowCheckedModeBanner: false,
          theme: meridianTheme(Brightness.light),
          darkTheme: meridianTheme(Brightness.dark),
          // Follows the phone unless the user picked Day or Night (DESIGN.md §2).
          themeMode: context.watch<ThemeProvider>().mode,
          // The app when signed in (always, in fake data mode), else sign-in.
          home: const AuthGate(),
        ),
      ),
    );
  }
}
