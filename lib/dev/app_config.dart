// Decides whether the app runs on fake data. See lib/services/README.md,
// "Fake data mode — why nobody waits".

import 'package:flutter/foundation.dart';

/// Supabase config, passed at build time with --dart-define (RUN.md).
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

const _forceFakeData = bool.fromEnvironment('USE_FAKE_DATA');

/// Tests set this to force a mode; leave it null in the app.
@visibleForTesting
bool? debugUseFakeData;

/// Fake data when asked for, or when there is no Supabase to talk to —
/// so a fresh clone runs with no keys at all.
bool get useFakeData => debugUseFakeData ?? (_forceFakeData || supabaseUrl.isEmpty);

/// What a service does in real mode before its owner has built it: fail
/// loudly and say where the work is tracked, never return fake data.
Never notBuiltYet(String what, int issue) {
  throw UnimplementedError(
    '$what is not built yet (issue #$issue). '
    'Run with --dart-define=USE_FAKE_DATA=true until it is.',
  );
}
