// Owner: Sanjay. "Email my emergency contact" (issue #48): a ready-made
// message the user sends from the phone's own mail app. Nothing is sent
// by the app — no server, no email service, no keys — the user presses
// Send. The contact's address lives in profiles.preferences as
// {"emergency_email": "..."}, next to the other keys already there.

import 'package:intl/intl.dart';

import '../../dev/app_config.dart';
import '../../dev/fake_data.dart';
import '../../models/user_profile.dart';
import '../../services/routing_service.dart';
import '../../services/supabase_service.dart';
import 'emergency_provider.dart';

const emergencyEmailKey = 'emergency_email';
const emergencyEmailSubject = 'Meridian: I need help';

/// The saved contact's address, or null if there isn't one yet.
String? emergencyEmailOf(UserProfile? profile) {
  final saved = profile?.preferences?[emergencyEmailKey];
  return (saved is String && saved.isNotEmpty) ? saved : null;
}

/// Good enough to catch a typo; the mail app is the real check.
bool looksLikeEmail(String text) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text.trim());

/// Saves the address into profiles.preferences, keeping every other key.
/// The caller reloads AccountsProvider's profile afterwards.
Future<void> saveEmergencyEmail(UserProfile profile, String email) async {
  final preferences = {...?profile.preferences, emergencyEmailKey: email.trim()};
  if (useFakeData) {
    fakeProfile = UserProfile(
      id: profile.id,
      fullName: profile.fullName,
      defaultCurrency: profile.defaultCurrency,
      preferences: preferences,
      createdAt: profile.createdAt,
    );
    return;
  }
  await supabaseClient.from('profiles').update({'preferences': preferences}).eq('id', profile.id);
}

/// An OpenStreetMap link that opens on the given point.
String mapLink(RoutePoint point) {
  final lat = point.latitude.toStringAsFixed(5);
  final lng = point.longitude.toStringAsFixed(5);
  return 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=17/$lat/$lng';
}

/// The message body. [savedPositionTime] is set when [position] is the
/// last known location rather than a live fix, so the reader knows how old it is.
String emergencyEmailBody({
  required RoutePoint? position,
  required DateTime? savedPositionTime,
  required DateTime now,
}) {
  final time = DateFormat('d MMM yyyy, HH:mm').format(now);
  final String where;
  if (position == null) {
    where = "My location isn't available right now.";
  } else if (savedPositionTime != null) {
    where = 'My phone has no GPS fix. My last known location, '
        'from ${formatAge(savedPositionTime, now)} (I may have moved since):\n${mapLink(position)}';
  } else {
    where = 'My location:\n${mapLink(position)}';
  }
  return 'I need help. Please try to reach me.\n\n'
      'Time: $time\n'
      '$where\n\n'
      'Sent by me from the Meridian travel app.';
}

/// A mailto: link the phone hands to its mail app.
Uri emergencyEmailUri({required String to, required String body}) {
  // Uri's queryParameters would turn spaces into "+", which some mail
  // apps show as-is, so the query is encoded by hand with %20.
  return Uri(
    scheme: 'mailto',
    path: to,
    query: 'subject=${Uri.encodeComponent(emergencyEmailSubject)}&body=${Uri.encodeComponent(body)}',
  );
}
