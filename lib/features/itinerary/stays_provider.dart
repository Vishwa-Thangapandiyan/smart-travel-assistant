// Owner: Vishwa. Where the traveller sleeps on each trip: a hotel, hostel
// or a friend's flat, found with Nominatim. Each day's route on the Map tab
// starts there, and so does Navigate to the first stop of a day.
//
// Kept on this phone only, in Hive: db/schema.sql and lib/models/ are
// frozen, so a trip has no column for it, and another phone won't see it.
// Syncing it would need a schema change — a team decision. Registered in
// lib/main.dart.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Stay {
  final String name;
  final double latitude;
  final double longitude;
  const Stay({required this.name, required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() => {'name': name, 'latitude': latitude, 'longitude': longitude};

  factory Stay.fromJson(Map<String, dynamic> json) => Stay(
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}

class StaysProvider extends ChangeNotifier {
  static const boxName = 'stays';

  // Trip id → JSON text of its stay. Without a box (widget tests) the
  // stays live in memory only.
  final Box<String>? _box;
  final _stays = <String, Stay>{};

  StaysProvider([this._box]) {
    final box = _box;
    if (box == null) return;
    for (final tripId in box.keys.cast<String>()) {
      _stays[tripId] = Stay.fromJson(jsonDecode(box.get(tripId)!) as Map<String, dynamic>);
    }
  }

  /// Null if no stay was set for the trip.
  Stay? stayFor(String tripId) => _stays[tripId];

  Future<void> setStay(String tripId, Stay stay) async {
    _stays[tripId] = stay;
    await _box?.put(tripId, jsonEncode(stay.toJson()));
    notifyListeners();
  }

  Future<void> removeStay(String tripId) async {
    _stays.remove(tripId);
    await _box?.delete(tripId);
    notifyListeners();
  }
}
