// Owner: Vishwa. The signed-in user (REQ-1.1). Supabase Auth does the
// password hashing and keeps the session; this file only calls it and
// makes sure every user has a `profiles` row. Registered in lib/main.dart.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../dev/app_config.dart';
import '../../dev/fake_data.dart';
import '../../services/supabase_service.dart';

class AccountsProvider extends ChangeNotifier {
  StreamSubscription<AuthState>? _authChanges;

  AccountsProvider() {
    // Sign-in, sign-out and token refresh all arrive here, so screens
    // watching this provider switch between sign-in and the app by themselves.
    if (!useFakeData) {
      _authChanges = supabaseClient.auth.onAuthStateChange.listen((_) => notifyListeners());
    }
  }

  /// Null when nobody is signed in. In fake data mode it is the demo user.
  String? get userId {
    if (useFakeData) return demoUserId;
    return supabaseClient.auth.currentUser?.id;
  }

  String? get email => useFakeData ? 'demo@meridian.dev' : supabaseClient.auth.currentUser?.email;

  bool get isSignedIn => userId != null;

  Future<void> signIn({required String email, required String password}) async {
    await supabaseClient.auth.signInWithPassword(email: email.trim(), password: password);
    await _makeProfileIfMissing();
  }

  /// False when Supabase wants the email confirmed before the first sign-in
  /// (no session yet); the profile row is then made on that first sign-in.
  Future<bool> signUp({required String email, required String password, required String fullName}) async {
    final response = await supabaseClient.auth.signUp(
      email: email.trim(),
      password: password,
      // Kept on the auth user, so the profile can still get the name if
      // the row is made later, on the first sign-in.
      data: {'full_name': fullName.trim()},
    );
    if (response.session == null) return false;
    await _makeProfileIfMissing();
    return true;
  }

  Future<void> signOut() => supabaseClient.auth.signOut();

  // Supabase Auth creates the auth.users row but not ours in `profiles`
  // (lib/features/accounts/README.md, task 3), so add it the first time.
  Future<void> _makeProfileIfMissing() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) return;
    final existing = await supabaseClient.from('profiles').select('id').eq('id', user.id).maybeSingle();
    if (existing != null) return;
    final name = user.userMetadata?['full_name'] as String?;
    await supabaseClient.from('profiles').insert({
      'id': user.id,
      'full_name': (name == null || name.isEmpty) ? null : name,
    });
  }

  @override
  void dispose() {
    _authChanges?.cancel();
    super.dispose();
  }
}
