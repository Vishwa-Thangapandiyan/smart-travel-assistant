// Owner: Vishwa (Maps, issue #59). Turn-by-turn directions are Google
// Maps' job, not ours: Navigate opens it with directions from wherever the
// phone is to one stop — or from the trip's stay, for the first stop of a
// day. It works offline too if the person saved that area in Google Maps.
// Used on the Map tab's stop card and the saved trip.

import 'package:url_launcher/url_launcher.dart';

import '../itinerary/stays_provider.dart';

/// Google Maps directions to a point, from [from] if given, otherwise from
/// wherever the phone is. On a phone with Google Maps this link opens the
/// app; otherwise it opens in the browser.
Uri directionsTo(double latitude, double longitude, {Stay? from}) {
  final origin = from == null ? '' : '&origin=${from.latitude},${from.longitude}';
  return Uri.parse('https://www.google.com/maps/dir/?api=1$origin&destination=$latitude,$longitude');
}

Future<void> openDirections(double latitude, double longitude, {Stay? from}) =>
    launchUrl(directionsTo(latitude, longitude, from: from), mode: LaunchMode.externalApplication);
