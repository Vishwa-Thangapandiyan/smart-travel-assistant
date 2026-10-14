import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_travel_assistant/features/itinerary/destination_lookup.dart';

// A trimmed copy of what Nominatim really returns for "Bangalore".
const _bangalore = [
  {
    'lat': '12.9767936',
    'lon': '77.5901604',
    'display_name': 'Bengaluru, Bangalore North, Bengaluru Urban, Karnataka, India',
  },
];

void main() {
  test('a known city comes back with its coordinates and full name', () async {
    final client = MockClient((_) async => http.Response(jsonEncode(_bangalore), 200));

    final match = await lookUpDestination('Bangalore', client: client);

    expect(match, isNotNull);
    expect(match!.latitude, 12.9767936);
    expect(match.longitude, 77.5901604);
    expect(match.name, startsWith('Bengaluru'));
  });

  test('asks Nominatim for one result and names the app, as its policy requires', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response('[]', 200);
    });

    await lookUpDestination('Bangalore', client: client);

    expect(sent.url.host, 'nominatim.openstreetmap.org');
    expect(sent.url.queryParameters['q'], 'Bangalore');
    expect(sent.url.queryParameters['limit'], '1');
    expect(sent.headers['User-Agent'], contains('Meridian'));
  });

  test('a name Nominatim does not know gives null', () async {
    final client = MockClient((_) async => http.Response('[]', 200));

    expect(await lookUpDestination('Qwertyuiop', client: client), isNull);
  });

  test('a server error or no internet gives null instead of crashing', () async {
    final down = MockClient((_) async => http.Response('busy', 503));
    final offline = MockClient((_) async => throw http.ClientException('no internet'));

    expect(await lookUpDestination('Bangalore', client: down), isNull);
    expect(await lookUpDestination('Bangalore', client: offline), isNull);
  });
}
