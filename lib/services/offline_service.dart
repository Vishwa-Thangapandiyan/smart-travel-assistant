// Owner: Sanjay (Offline, REQ-4.3). Signature fixed in
// lib/services/README.md. A download is a copy of the trip, its stops,
// the destination's guide text, each day's route and ONE static map
// picture per day, kept in Hive on the phone with the time it was taken.
// Each picture is a few OpenStreetMap tiles laid side by side; it is not a
// pannable offline map.
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
import 'routing_service.dart';
import 'supabase_service.dart';
import 'trip_service.dart';

class SavedTrip {
  final Trip trip;
  final List<ItineraryItem> items;
  final String? guideText; // from the offline_packs row, if any
  final Map<int, StaticMapArea> mapAreas; // what each day's saved map shows, by day number
  final Map<String, Uint8List> mapTiles; // the map tiles by URL; days can share tiles
  final Map<int, List<RoutePoint>> routes; // road route per day number, where OSRM answered
  final DateTime downloadedAt;
  const SavedTrip({
    required this.trip,
    required this.items,
    this.guideText,
    this.mapAreas = const {},
    this.mapTiles = const {},
    this.routes = const {},
    required this.downloadedAt,
  });
}

/// The square of the world one day's saved map shows: [size] tiles across
/// and down (512 px) at [zoom], centred on ([latitude], [longitude]).
/// Picked at download so all the day's stops and route fit (issue #59).
class StaticMapArea {
  static const size = 2;
  final int zoom;
  final double latitude;
  final double longitude;
  const StaticMapArea({required this.zoom, required this.latitude, required this.longitude});

  /// The same view on openstreetmap.org, recorded in `static_map_url`.
  String get url => 'https://www.openstreetmap.org/#map=$zoom/${latitude.toStringAsFixed(5)}/${longitude.toStringAsFixed(5)}';

  /// Where a point falls on the map, from 0 to 1 across and down, or null
  /// if it's off the map. Used to draw stops and routes on the saved tiles.
  ({double across, double down})? positionOf(double latitude, double longitude) {
    final centre = _tileCoordinates(this.latitude, this.longitude, zoom);
    final point = _tileCoordinates(latitude, longitude, zoom);
    final across = (point.tileX - centre.tileX) / size + 0.5;
    final down = (point.tileY - centre.tileY) / size + 0.5;
    if (across < 0 || across > 1 || down < 0 || down > 1) return null;
    return (across: across, down: down);
  }

  /// The OpenStreetMap tiles that cover the map, and where each one's top
  /// left corner goes, from 0 to 1 across and down. The centre rarely sits
  /// on a tile edge, so it takes up to 3 × 3 tiles to cover 2 × 2.
  List<({String url, double across, double down})> get tiles {
    final centre = _tileCoordinates(latitude, longitude, zoom);
    final left = centre.tileX - size / 2;
    final top = centre.tileY - size / 2;
    final tilesAcross = pow(2, zoom).toInt();
    return [
      for (var y = top.floor(); y < top + size; y++)
        for (var x = left.floor(); x < left + size; x++)
          if (y >= 0 && y < tilesAcross)
            (
              // x % tilesAcross wraps round the 180th meridian.
              url: 'https://tile.openstreetmap.org/$zoom/${x % tilesAcross}/$y.png',
              across: (x - left) / size,
              down: (y - top) / size,
            ),
    ];
  }
}

/// The closest zoom (street level, 16, at most) at which every point fits
/// on the map with a quarter tile to spare at the edges. Null for no points.
StaticMapArea? staticMapAreaFor(List<RoutePoint> points) {
  if (points.isEmpty) return null;
  final south = points.map((p) => p.latitude).reduce(min);
  final north = points.map((p) => p.latitude).reduce(max);
  final west = points.map((p) => p.longitude).reduce(min);
  final east = points.map((p) => p.longitude).reduce(max);
  final latitude = (south + north) / 2;
  final longitude = (west + east) / 2;

  for (var zoom = 16; zoom > 3; zoom--) {
    final centre = _tileCoordinates(latitude, longitude, zoom);
    final northWest = _tileCoordinates(north, west, zoom);
    final southEast = _tileCoordinates(south, east, zoom);
    const room = StaticMapArea.size / 2 - 0.25;
    final fits = centre.tileX - northWest.tileX <= room &&
        southEast.tileX - centre.tileX <= room &&
        centre.tileY - northWest.tileY <= room &&
        southEast.tileY - centre.tileY <= room;
    if (fits) return StaticMapArea(zoom: zoom, latitude: latitude, longitude: longitude);
  }
  return StaticMapArea(zoom: 3, latitude: latitude, longitude: longitude);
}

/// A map area for every day that has a placed stop, fitting its stops and
/// its route. One map per day stays readable: a whole trip, with the
/// airport 30 km out, would shrink the city stops into one blob.
Map<int, StaticMapArea> dayMapAreas(Trip trip, List<ItineraryItem> items, Map<int, List<RoutePoint>> routes) {
  final areas = <int, StaticMapArea>{};
  for (var day = 1; day <= trip.numberOfDays; day++) {
    final area = staticMapAreaFor([
      for (final item in items)
        if (item.dayNumber == day && item.latitude != null && item.longitude != null)
          RoutePoint(item.latitude!, item.longitude!),
      ...?routes[day],
    ]);
    if (area != null) areas[day] = area;
  }
  return areas;
}

// The standard "slippy map" formula OpenStreetMap tiles use (Web
// Mercator): the whole part is the tile number, the rest is the position inside it.
({double tileX, double tileY}) _tileCoordinates(double latitude, double longitude, int zoom) {
  final tiles = pow(2, zoom).toDouble();
  final latRad = latitude * pi / 180;
  return (
    tileX: (longitude + 180) / 360 * tiles,
    tileY: (1 - log(tan(latRad) + 1 / cos(latRad)) / pi) / 2 * tiles,
  );
}

/// The road route through each day's placed stops, in order. A day with
/// fewer than two placed stops, or that OSRM can't route, has no entry.
Future<Map<int, List<RoutePoint>>> _dayRoutes(Trip trip, List<ItineraryItem> items) async {
  final routes = <int, List<RoutePoint>>{};
  for (var day = 1; day <= trip.numberOfDays; day++) {
    final stops = [
      for (final item in items)
        if (item.dayNumber == day && item.latitude != null && item.longitude != null)
          RoutePoint(item.latitude!, item.longitude!),
    ];
    if (stops.length < 2) continue;
    try {
      routes[day] = _thinned((await getRouteThrough(stops)).points);
    } catch (_) {
      // No line for this day; its stops are still drawn.
    }
  }
  return routes;
}

// OSRM can return thousands of points for a day. A few hundred draw the
// same line on a 768 px map and keep the Hive copy small.
List<RoutePoint> _thinned(List<RoutePoint> points) {
  const most = 300;
  if (points.length <= most) return points;
  final step = (points.length / most).ceil();
  return [
    for (var i = 0; i < points.length; i += step) points[i],
    points.last,
  ];
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
  final routes = await _dayRoutes(trip, items);
  final mapAreas = dayMapAreas(trip, items, routes);

  if (useFakeData) {
    // No internet in fake mode, so no map tiles; the stops and the demo
    // route lines are still saved and drawn.
    _fakeDownloads[tripId] = SavedTrip(
      trip: trip,
      items: items,
      guideText: guideText,
      mapAreas: mapAreas,
      routes: routes,
      downloadedAt: DateTime.now(),
    );
    return;
  }

  final mapTiles = await _downloadTiles(mapAreas.values);
  await storeSavedTrip(SavedTrip(
    trip: trip,
    items: items,
    guideText: guideText,
    mapAreas: mapAreas,
    mapTiles: mapTiles,
    routes: routes,
    downloadedAt: DateTime.now(),
  ));

  try {
    // One row per user and trip; downloading again updates it.
    await supabaseClient.from('offline_packs').upsert({
      'user_id': trip.userId,
      'trip_id': trip.id,
      'guide_text': guideText,
      'static_map_url': mapTiles.isEmpty ? null : mapAreas.values.first.url,
      'downloaded_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,trip_id');
  } catch (_) {
    // Don't keep a copy the database has no record of.
    await (await _savedTrips()).delete(tripId);
    rethrow;
  }
}

// Keeps the Hive copy under 1 MB (a few KB of trip text plus the tiles).
const _tileBudgetBytes = 900 * 1024;

// The tiles under every day's map, one at a time as OpenStreetMap's tile
// policy prefers, each fetched once even if several days need it. Stops
// at the budget; a day missing a tile draws its stops and route on a
// plain background instead.
Future<Map<String, Uint8List>> _downloadTiles(Iterable<StaticMapArea> areas) async {
  final tiles = <String, Uint8List>{};
  var bytes = 0;
  for (final area in areas) {
    for (final tile in area.tiles) {
      if (tiles.containsKey(tile.url)) continue;
      final image = await _downloadImage(tile.url);
      if (image == null) continue;
      if (bytes + image.length > _tileBudgetBytes) return tiles;
      tiles[tile.url] = image;
      bytes += image.length;
    }
  }
  return tiles;
}

// Null if the image can't be fetched.
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

/// Writes [saved] into Hive: the trip, stops, map areas and routes as
/// JSON text, the map tiles as bytes. Hive keeps it until the trip is
/// downloaded again.
@visibleForTesting
Future<void> storeSavedTrip(SavedTrip saved) async {
  final box = await _savedTrips();
  await box.put(saved.trip.id, {
    'json': jsonEncode({
      'trip': saved.trip.toJson(),
      'items': [for (final item in saved.items) item.toJson()],
      'guide_text': saved.guideText,
      'map_areas': {
        for (final entry in saved.mapAreas.entries)
          '${entry.key}': {'zoom': entry.value.zoom, 'latitude': entry.value.latitude, 'longitude': entry.value.longitude},
      },
      // Day number → [[latitude, longitude], ...], five decimals (about 1 m).
      'routes': {
        for (final entry in saved.routes.entries)
          '${entry.key}': [
            for (final point in entry.value)
              [double.parse(point.latitude.toStringAsFixed(5)), double.parse(point.longitude.toStringAsFixed(5))],
          ],
      },
      'downloaded_at': saved.downloadedAt.toIso8601String(),
    }),
    'map_tiles': saved.mapTiles,
  });
}

/// Null if the trip was never downloaded. A copy saved before issue #59
/// has no map areas or routes; it shows without a map until downloaded again.
Future<SavedTrip?> loadSavedTrip(String tripId) async {
  if (useFakeData) return _fakeDownloads[tripId];

  final stored = (await _savedTrips()).get(tripId) as Map?;
  if (stored == null) return null;
  final json = jsonDecode(stored['json'] as String) as Map<String, dynamic>;
  final areas = json['map_areas'] as Map<String, dynamic>? ?? {};
  final routes = json['routes'] as Map<String, dynamic>? ?? {};
  return SavedTrip(
    trip: Trip.fromJson(json['trip'] as Map<String, dynamic>),
    items: [
      for (final item in json['items'] as List<dynamic>) ItineraryItem.fromJson(item as Map<String, dynamic>),
    ],
    guideText: json['guide_text'] as String?,
    mapAreas: {
      for (final entry in areas.entries)
        int.parse(entry.key): StaticMapArea(
          zoom: entry.value['zoom'] as int,
          latitude: (entry.value['latitude'] as num).toDouble(),
          longitude: (entry.value['longitude'] as num).toDouble(),
        ),
    },
    mapTiles: {
      for (final entry in (stored['map_tiles'] as Map<dynamic, dynamic>? ?? {}).entries)
        entry.key as String: entry.value as Uint8List,
    },
    routes: {
      for (final entry in routes.entries)
        int.parse(entry.key): [
          for (final pair in (entry.value as List<dynamic>).cast<List<dynamic>>())
            RoutePoint((pair[0] as num).toDouble(), (pair[1] as num).toDouble()),
        ],
    },
    downloadedAt: DateTime.parse(json['downloaded_at'] as String),
  );
}

Future<bool> isDownloaded(String tripId) async {
  if (useFakeData) return _fakeDownloads.containsKey(tripId);
  return (await _savedTrips()).containsKey(tripId);
}
