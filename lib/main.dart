// Entry point. Starts Supabase (unless running on fake data), registers
// every feature's Provider once, and applies the Meridian theme. Feature
// owners fill in their own provider and screen files — this file should
// rarely need to change.
//
// Supabase config comes from --dart-define, not a .env file (RUN.md).

import 'package:flutter/material.dart';
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

  runApp(const MeridianApp());
}

class MeridianApp extends StatelessWidget {
  const MeridianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountsProvider()),
        ChangeNotifierProvider(create: (_) => ItineraryProvider()),
        ChangeNotifierProvider(create: (_) => MapsProvider()),
        ChangeNotifierProvider(create: (_) => OfflineProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationsProvider()),
      ],
      child: MaterialApp(
        title: 'Meridian',
        debugShowCheckedModeBanner: false,
        theme: meridianTheme(Brightness.light),
        darkTheme: meridianTheme(Brightness.dark),
        // Night first (DESIGN.md §2). Following the phone's setting is
        // proposed but not decided, so this stays fixed for now.
        themeMode: ThemeMode.dark,
        // The app when signed in (always, in fake data mode), else sign-in.
        home: const AuthGate(),
      ),
    );
  }
}
