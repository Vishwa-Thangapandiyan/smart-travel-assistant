import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/services/routing_service.dart';

// A trimmed copy of a real OSRM answer: GeoJSON puts longitude first.
final _osrmAnswer = jsonEncode({
  'code': 'Ok',
  'routes': [
    {
      'distance': 7123.4,
      'duration': 731.2,
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [77.58483, 12.95073],
          [77.58800, 12.97000],
          [77.59212, 12.99876],
        ],
      },
      'legs': [
        {'distance': 7123.4, 'duration': 731.2},
      ],
    },
  ],
});

const _lalbagh = RoutePoint(12.95073, 77.58483);
const _palace = RoutePoint(12.99876, 77.59212);
const _cubbon = RoutePoint(12.97633, 77.59292);

void main() {
  setUp(() => debugUseFakeData = false);
  tearDown(() => debugUseFakeData = null);

  test('the road path comes back as latitude/longitude points with distance and time', () async {
    final client = MockClient((_) async => http.Response(_osrmAnswer, 200));

    final route = await getRouteThrough([_lalbagh, _palace], client: client);

    expect(route.points, hasLength(3));
    expect(route.points.first.latitude, 12.95073);
    expect(route.points.first.longitude, 77.58483);
    expect(route.distanceMeters, 7123.4);
    expect(route.durationSeconds, 731.2);
  });

  test('every stop of the day goes to OSRM in one request, longitude first', () async {
    late Uri asked;
    final client = MockClient((request) async {
      asked = request.url;
      return http.Response(_osrmAnswer, 200);
    });

    await getRouteThrough([_lalbagh, _palace, _cubbon], client: client);

    expect(asked.host, 'router.project-osrm.org');
    expect(asked.path, '/route/v1/driving/77.58483,12.95073;77.59212,12.99876;77.59292,12.97633');
    expect(asked.queryParameters['geometries'], 'geojson');
    expect(asked.queryParameters['overview'], 'full');
  });

  test('a non-200 answer throws, so the caller can keep its pins and drop the line', () async {
    final client = MockClient((_) async => http.Response('too many requests', 429));

    expect(getRouteThrough([_lalbagh, _palace], client: client), throwsA(isA<RouteException>()));
  });

  test('OSRM saying it found no route throws too', () async {
    final client = MockClient((_) async => http.Response(jsonEncode({'code': 'NoRoute', 'routes': []}), 200));

    expect(getRouteThrough([_lalbagh, _palace], client: client), throwsA(isA<RouteException>()));
  });

  test('fewer than two stops is not a route', () {
    expect(getRouteThrough([_lalbagh]), throwsA(isA<ArgumentError>()));
  });

  test('in fake data mode the line runs straight through every stop', () async {
    debugUseFakeData = true;

    final route = await getRouteThrough([_lalbagh, _palace, _cubbon]);

    expect(route.points.first.latitude, _lalbagh.latitude);
    expect(route.points.last.latitude, _cubbon.latitude);
    expect(route.points.map((p) => p.latitude), contains(_palace.latitude));
    expect(route.distanceMeters, greaterThan(0));
  });
}
