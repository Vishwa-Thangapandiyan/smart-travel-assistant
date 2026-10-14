// Owner: Sanjay (Offline, REQ-4.3). Signature fixed in
// lib/services/README.md. The real Hive version arrives with issue #25.

import 'package:flutter/foundation.dart'; // also provides Uint8List

import '../dev/app_config.dart';
import '../dev/fake_data.dart';
import '../models/itinerary_item.dart';
import '../models/trip.dart';
import 'trip_service.dart';

class SavedTrip {
  final Trip trip;
  final List<ItineraryItem> items;
  final String? guideText; // from the offline_packs row, if any
  final Uint8List? mapImage; // the one static map image, if it downloaded
  final DateTime downloadedAt;
  const SavedTrip({
    required this.trip,
    required this.items,
    this.guideText,
    this.mapImage,
    required this.downloadedAt,
  });
}

// Fake mode keeps downloads in memory for the life of the app.
final _fakeDownloads = <String, SavedTrip>{};

@visibleForTesting
void resetFakeDownloads() => _fakeDownloads.clear();

/// Fetches via trip_service, writes Hive, records an OfflinePack row.
Future<void> downloadTrip(String tripId) async {
  if (!useFakeData) notBuiltYet('offline_service', 25);
  final trip = await getTrip(tripId);
  if (trip == null) return;
  _fakeDownloads[tripId] = SavedTrip(
    trip: trip,
    items: await getItineraryItems(tripId),
    guideText: demoGuideText,
    downloadedAt: DateTime.now(),
  );
}

/// Null if the trip was never downloaded.
Future<SavedTrip?> loadSavedTrip(String tripId) async {
  if (!useFakeData) notBuiltYet('offline_service', 25);
  return _fakeDownloads[tripId];
}

Future<bool> isDownloaded(String tripId) async {
  if (!useFakeData) notBuiltYet('offline_service', 25);
  return _fakeDownloads.containsKey(tripId);
}
