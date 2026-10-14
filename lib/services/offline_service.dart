// Owner: Sanjay (Offline, REQ-4.3). Signature fixed in
// lib/services/README.md. A download is a copy of the trip, its stops,
// the destination's guide text and ONE static map image, kept in Hive on
// the phone with the time it was taken. It is not a pannable offline map.
// The offline_packs row in Supabase only records that the download happened.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart'; // also provides Uint8List
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../dev/app_config.dart';
import '../features/offline/destination_guides.dart';
import '../models/itinerary_item.dart';
import '../models/trip.dart';
import 'supabase_service.dart';
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

/// The one OpenStreetMap tile (256 × 256 px) that holds the trip's centre.
/// At zoom 12 one tile is about 10 km across in India — a city overview.
class StaticMapTile {
  static const zoom = 12;
  final int x;
  final int y;
  const StaticMapTile(this.x, this.y);

  String get url => 'https://tile.openstreetmap.org/$zoom/$x/$y.png';

  /// Where a point falls on the tile, from 0 to 1 across and down, or
  /// null if it's outside the tile. Used to draw stops on the saved image.
  ({double across, double down})? positionOf(double latitude, double longitude) {
    final (:tileX, :tileY) = _tileCoordinates(latitude, longitude);
    final across = tileX - x;
    final down = tileY - y;
    if (across < 0 || across >= 1 || down < 0 || down >= 1) return null;
    return (across: across, down: down);
  }
}

/// The tile for the trip's own coordinates, or its first placed stop if
/// the trip has none. Null if there is nothing to centre on.
StaticMapTile? staticMapTileFor(Trip trip, List<ItineraryItem> items) {
  var lat = trip.latitude;
  var lng = trip.longitude;
  if (lat == null || lng == null) {
    final placed = items.where((i) => i.latitude != null && i.longitude != null).firstOrNull;
    lat = placed?.latitude;
    lng = placed?.longitude;
  }
  if (lat == null || lng == null) return null;
  final (:tileX, :tileY) = _tileCoordinates(lat, lng);
  return StaticMapTile(tileX.floor(), tileY.floor());
}

// The standard "slippy map" formula OpenStreetMap tiles use (Web
// Mercator): the whole part is the tile number, the rest is the position inside it.
({double tileX, double tileY}) _tileCoordinates(double latitude, double longitude) {
  final tiles = pow(2, StaticMapTile.zoom).toDouble();
  final latRad = latitude * pi / 180;
  return (
    tileX: (longitude + 180) / 360 * tiles,
    tileY: (1 - log(tan(latRad) + 1 / cos(latRad)) / pi) / 2 * tiles,
  );
}

// Fake mode keeps downloads in memory for the life of the app.
final _fakeDownloads = <String, SavedTrip>{};

const _boxName = 'saved_trips';
Box<dynamic>? _box;
bool _hiveReady = false;

Future<Box<dynamic>> _savedTrips() async {
  if (_box != null && _box!.isOpen) return _box!;
  if (!_hiveReady) {
    await Hive.initFlutter();
    _hiveReady = true;
  }
  return _box = await Hive.openBox(_boxName);
}

/// Tests have no app folder for Hive, so they hand it a temporary one.
@visibleForTesting
void useHiveFolderForTests(String path) {
  Hive.init(path);
  _hiveReady = true;
}

@visibleForTesting
Future<void> resetFakeDownloads() async {
  _fakeDownloads.clear();
  if (_box != null && _box!.isOpen) await _box!.clear();
}

/// Fetches via trip_service, writes Hive, records an OfflinePack row.
/// Throws if there's no connection; nothing is saved then.
Future<void> downloadTrip(String tripId) async {
  final trip = await getTrip(tripId);
  if (trip == null) throw StateError('Trip $tripId not found');
  final items = await getItineraryItems(tripId);
  final guideText = guideFor(trip.destination);
  final tile = staticMapTileFor(trip, items);

  if (useFakeData) {
    // No internet in fake mode, so no map image.
    _fakeDownloads[tripId] = SavedTrip(trip: trip, items: items, guideText: guideText, downloadedAt: DateTime.now());
    return;
  }

  final mapImage = tile == null ? null : await _downloadImage(tile.url);
  await storeSavedTrip(SavedTrip(
    trip: trip,
    items: items,
    guideText: guideText,
    mapImage: mapImage,
    downloadedAt: DateTime.now(),
  ));

  try {
    // One row per user and trip; downloading again updates it.
    await supabaseClient.from('offline_packs').upsert({
      'user_id': trip.userId,
      'trip_id': trip.id,
      'guide_text': guideText,
      'static_map_url': mapImage == null ? null : tile!.url,
      'downloaded_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,trip_id');
  } catch (_) {
    // Don't keep a copy the database has no record of.
    await (await _savedTrips()).delete(tripId);
    rethrow;
  }
}

// Null if the image can't be fetched — the rest of the trip still saves.
Future<Uint8List?> _downloadImage(String url) async {
  try {
    final response = await http.get(Uri.parse(url), headers: {
      // OpenStreetMap's tile policy asks every app to say who it is.
      'User-Agent': 'Meridian travel planner (VIT Chennai student project)',
    }).timeout(const Duration(seconds: 15));
    return response.statusCode == 200 ? response.bodyBytes : null;
  } catch (_) {
    return null;
  }
}

/// Writes [saved] into Hive: the trip and stops as JSON text, the map
/// image as bytes. Hive keeps it until the trip is downloaded again.
@visibleForTesting
Future<void> storeSavedTrip(SavedTrip saved) async {
  final box = await _savedTrips();
  await box.put(saved.trip.id, {
    'json': jsonEncode({
      'trip': saved.trip.toJson(),
      'items': [for (final item in saved.items) item.toJson()],
      'guide_text': saved.guideText,
      'downloaded_at': saved.downloadedAt.toIso8601String(),
    }),
    'map_image': saved.mapImage,
  });
}

/// Null if the trip was never downloaded.
Future<SavedTrip?> loadSavedTrip(String tripId) async {
  if (useFakeData) return _fakeDownloads[tripId];

  final stored = (await _savedTrips()).get(tripId) as Map?;
  if (stored == null) return null;
  final json = jsonDecode(stored['json'] as String) as Map<String, dynamic>;
  return SavedTrip(
    trip: Trip.fromJson(json['trip'] as Map<String, dynamic>),
    items: [
      for (final item in json['items'] as List<dynamic>) ItineraryItem.fromJson(item as Map<String, dynamic>),
    ],
    guideText: json['guide_text'] as String?,
    mapImage: stored['map_image'] as Uint8List?,
    downloadedAt: DateTime.parse(json['downloaded_at'] as String),
  );
}

Future<bool> isDownloaded(String tripId) async {
  if (useFakeData) return _fakeDownloads.containsKey(tripId);
  return (await _savedTrips()).containsKey(tripId);
}
