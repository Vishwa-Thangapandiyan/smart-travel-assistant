import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/services/overpass_service.dart';

// A trimmed copy of a real Overpass answer: a hospital node with a name
// and phone, a police building (a way, so its position is "center"), an
// unnamed hospital, and an entry with no position at all.
final _overpassAnswer = jsonEncode({
  'elements': [
    {
      'type': 'node',
      'id': 1,
      'lat': 12.9824,
      'lon': 77.6065,
      'tags': {'amenity': 'hospital', 'name': 'Bowring and Lady Curzon Hospital', 'phone': '+91 80 1111 2222;+91 80 3333 4444'},
    },
    {
      'type': 'way',
      'id': 2,
      'center': {'lat': 12.9775, 'lon': 77.5966},
      'tags': {'amenity': 'police', 'name': 'Cubbon Park Police Station'},
    },
    {
      'type': 'node',
      'id': 3,
      'lat': 12.9590,
      'lon': 77.6010,
      'tags': {'amenity': 'hospital', 'name': '  '},
    },
    {
      'type': 'relation',
      'id': 4,
      'tags': {'amenity': 'hospital', 'name': 'No position'},
    },
  ],
});

void main() {
  setUp(() => debugUseFakeData = false);
  tearDown(() => debugUseFakeData = null);

  test('hospitals and police come back with positions, names and the first phone number', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response(_overpassAnswer, 200);
    });

    final places = await findNearbyEmergencyServices(latitude: 12.97, longitude: 77.59, client: client);

    expect(sent.url.host, 'overpass-api.de');
    expect(sent.bodyFields['data'], contains('around:5000,12.97,77.59'));
    expect(places, hasLength(3));

    final hospital = places[0];
    expect(hospital.name, 'Bowring and Lady Curzon Hospital');
    expect(hospital.amenityType, 'hospital');
    expect(hospital.phone, '+91 80 1111 2222');

    final police = places[1];
    expect(police.amenityType, 'police');
    expect(police.latitude, 12.9775);
    expect(police.phone, isNull);
  });

  test('a blank name is treated as no name', () async {
    final client = MockClient((_) async => http.Response(_overpassAnswer, 200));

    final places = await findNearbyEmergencyServices(latitude: 12.97, longitude: 77.59, client: client);

    expect(places[2].name, isNull);
  });

  test('rate-limited or busy answers throw, so the screen can say so', () async {
    for (final status in [429, 504]) {
      final client = MockClient((_) async => http.Response('busy', status));

      expect(
        findNearbyEmergencyServices(latitude: 12.97, longitude: 77.59, client: client),
        throwsA(isA<OverpassException>()),
      );
    }
  });

  test('an empty answer is an empty list, not an error', () async {
    final client = MockClient((_) async => http.Response(jsonEncode({'elements': []}), 200));

    expect(await findNearbyEmergencyServices(latitude: 0, longitude: 0, client: client), isEmpty);
  });
}
