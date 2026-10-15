// Owner: Vishwa (Maps, issue #59). Turn-by-turn directions are Google
// Maps' job, not ours: Navigate opens it with directions from wherever the
// phone is to one stop. It works offline too if the person saved that
// area in Google Maps. Used on the Map tab's stop card and the saved trip.

import 'package:url_launcher/url_launcher.dart';

/// Google Maps directions to a point. On a phone with Google Maps this
/// link opens the app; otherwise it opens in the browser.
Uri directionsTo(double latitude, double longitude) =>
    Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude');

Future<void> openDirections(double latitude, double longitude) =>
    launchUrl(directionsTo(latitude, longitude), mode: LaunchMode.externalApplication);
