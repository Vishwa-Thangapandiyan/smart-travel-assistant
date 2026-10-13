// Entry point. Initialises Supabase and wraps the app in the Provider
// tree every feature reads from. Feature owners add their own
// ChangeNotifierProvider entries here as they build screens — this file
// stays shared, so check with the group before restructuring it.
//
// Supabase config comes from --dart-define, not a .env file (see RUN.md
// for the exact command). String.fromEnvironment reads values baked in
// at build time; there is nothing to load at runtime and nothing to
// gitignore beyond the command itself.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing Supabase config. Run with --dart-define=SUPABASE_URL=... '
      '--dart-define=SUPABASE_ANON_KEY=... — see RUN.md.',
    );
  }

  // Supabase renamed the anon key to the "publishable" key; it is the
  // same public value, so the --dart-define name stays as it is.
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  runApp(const SmartTravelApp());
}

class SmartTravelApp extends StatelessWidget {
  const SmartTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Feature owners: add your ChangeNotifierProvider here, not inside
      // individual screens, so every screen sees the same instance.
      providers: const [],
      child: MaterialApp(
        title: 'Smart Travel Planning Assistant',
        theme: ThemeData(useMaterial3: true),
        home: const _SetupCheckScreen(),
      ),
    );
  }
}

class _SetupCheckScreen extends StatelessWidget {
  const _SetupCheckScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Setup is working. Open your task brief in team/ to start.'),
      ),
    );
  }
}
