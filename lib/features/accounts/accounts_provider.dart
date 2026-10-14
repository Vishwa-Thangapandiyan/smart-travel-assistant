// Owner: Vishwa. The signed-in user (REQ-1.1). Supabase Auth does the
// password hashing and keeps the session; this file only calls it and
// makes sure every user has a `profiles` row. Registered in lib/main.dart.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../dev/app_config.dart';
import '../../dev/fake_data.dart';
import '../../models/user_profile.dart';
import '../../services/supabase_service.dart';

class AccountsProvider extends ChangeNotifier {
  StreamSubscription<AuthState>? _authChanges;

  AccountsProvider() {
    // Sign-in, sign-out and token refresh all arrive here, so screens
    // watching this provider switch between sign-in and the app by themselves.
    if (!useFakeData) {
      _authChanges = supabaseClient.auth.onAuthStateChange.listen((change) {
        // Google sign-in finishes here, when the browser hands the session back.
        if (change.event == AuthChangeEvent.signedIn) _makeProfileIfMissing();
        notifyListeners();
      });
    }
  }

  /// Null when nobody is signed in. In fake data mode it is the demo user.
  String? get userId {
    if (useFakeData) return demoUserId;
    return supabaseClient.auth.currentUser?.id;
  }

  String? get email => useFakeData ? 'demo@meridian.dev' : supabaseClient.auth.currentUser?.email;

  bool get isSignedIn => userId != null;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  /// The place categories the user picked as interests, stored as
  /// {"interests": [...]} in profiles.preferences. They never shape a trip.
  List<String> get interests {
    final saved = _profile?.preferences?['interests'];
    return saved is List ? saved.cast<String>() : [];
  }

  Future<void> loadProfile() async {
    if (useFakeData) {
      _profile = fakeProfile;
    } else {
      final id = userId;
      if (id == null) return;
      final row = await supabaseClient.from('profiles').select().eq('id', id).maybeSingle();
      _profile = row == null ? null : UserProfile.fromJson(row);
    }
    notifyListeners();
  }

  Future<void> saveProfile({
    required String fullName,
    required String defaultCurrency,
    required List<String> interests,
  }) async {
    final current = _profile!;
    final name = fullName.trim().isEmpty ? null : fullName.trim();
    // Keep any other preference keys a later feature may have added.
    final preferences = {...?current.preferences, 'interests': interests};

    if (!useFakeData) {
      await supabaseClient.from('profiles').update({
        'full_name': name,
        'default_currency': defaultCurrency,
        'preferences': preferences,
      }).eq('id', current.id);
    }
    _profile = UserProfile(
      id: current.id,
      fullName: name,
      defaultCurrency: defaultCurrency,
      preferences: preferences,
      createdAt: current.createdAt,
    );
    if (useFakeData) fakeProfile = _profile!;
    notifyListeners();
  }

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

  /// Opens Google in the browser. The session arrives later through the
  /// link dev.meridian.travel://login-callback (see AndroidManifest.xml).
  Future<void> signInWithGoogle() async {
    await supabaseClient.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: googleRedirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  static const googleRedirect = 'dev.meridian.travel://login-callback';

  Future<void> signOut() => supabaseClient.auth.signOut();

  // Supabase Auth creates the auth.users row but not ours in `profiles`
  // (lib/features/accounts/README.md, task 3), so add it the first time.
  // Runs on every sign-in, so it must be harmless when the row exists:
  // ignoreDuplicates makes it "insert, or do nothing".
  Future<void> _makeProfileIfMissing() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) return;
    // Email sign-up stores full_name; Google sends full_name (or name).
    final name = (user.userMetadata?['full_name'] ?? user.userMetadata?['name']) as String?;
    await supabaseClient.from('profiles').upsert(
      {'id': user.id, 'full_name': (name == null || name.isEmpty) ? null : name},
      onConflict: 'id',
      ignoreDuplicates: true,
    );
  }

  @override
  void dispose() {
    _authChanges?.cancel();
    super.dispose();
  }
}
