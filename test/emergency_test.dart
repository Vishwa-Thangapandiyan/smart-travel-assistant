import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_data.dart';
import 'package:smart_travel_assistant/features/accounts/accounts_provider.dart';
import 'package:smart_travel_assistant/features/emergency/directions_screen.dart';
import 'package:smart_travel_assistant/features/emergency/emergency_email.dart';
import 'package:smart_travel_assistant/features/emergency/emergency_provider.dart';
import 'package:smart_travel_assistant/features/emergency/emergency_screen.dart';
import 'package:smart_travel_assistant/services/overpass_service.dart';
import 'package:smart_travel_assistant/services/routing_service.dart';
import 'package:smart_travel_assistant/theme/meridian_theme.dart';

Future<RoutePoint?> _noGps() async => null;

Future<List<OverpassPlace>> _overpassDown({required double latitude, required double longitude}) async {
  throw const OverpassException('Overpass answered 429');
}

const _bowring = OverpassPlace(
  name: 'Bowring and Lady Curzon Hospital',
  amenityType: 'hospital',
  latitude: 12.9824,
  longitude: 77.6065,
);

void main() {
  setUp(() {
    debugUseFakeData = true;
    resetFakeProfile();
  });
  tearDown(() => debugUseFakeData = null);

  group('EmergencyProvider', () {
    test('helplines are there before anything loads', () {
      final emergency = EmergencyProvider();

      expect(emergency.helplines.map((h) => h.phoneNumber), containsAll(['112', '100', '108', '101']));
    });

    test('with GPS, nearby places are sorted nearest first', () async {
      final emergency = EmergencyProvider();

      await emergency.load(demoUserId);

      expect(emergency.usingSavedPosition, isFalse);
      expect(emergency.nearbyStatus, NearbyStatus.loaded);
      final distances = emergency.nearby.map((n) => n.distanceMeters).toList();
      expect(distances, [...distances]..sort());
      expect(emergency.nearby.first.place.name, 'Cubbon Park Police Station');
    });

    test('with no GPS, the saved location is used and marked as saved (REQ-5.4)', () async {
      final emergency = EmergencyProvider(currentPosition: _noGps);

      await emergency.load(demoUserId);

      expect(emergency.usingSavedPosition, isTrue);
      expect(emergency.savedPositionTime!.isBefore(DateTime.now()), isTrue);
      expect(emergency.position, isNotNull);
      expect(emergency.nearbyStatus, NearbyStatus.loaded);
    });

    test('with no GPS and nothing saved, it says so and keeps the helplines', () async {
      final emergency = EmergencyProvider(currentPosition: _noGps);

      await emergency.load('someone-with-no-saved-location');

      expect(emergency.position, isNull);
      expect(emergency.nearbyStatus, NearbyStatus.noLocation);
      expect(emergency.helplines, isNotEmpty);
    });

    test('when Overpass fails, the list fails and the helplines stay', () async {
      final emergency = EmergencyProvider(findNearby: _overpassDown);

      await emergency.load(demoUserId);

      expect(emergency.nearbyStatus, NearbyStatus.failed);
      expect(emergency.nearby, isEmpty);
      expect(emergency.helplines.map((h) => h.phoneNumber), contains('112'));
    });
  });

  group('wording', () {
    test('an entry with no name gets a readable title', () {
      const unnamed = OverpassPlace(amenityType: 'hospital', latitude: 0, longitude: 0);
      const unnamedPolice = OverpassPlace(name: '', amenityType: 'police', latitude: 0, longitude: 0);

      expect(placeTitle(unnamed), 'Unnamed hospital');
      expect(placeTitle(unnamedPolice), 'Unnamed police station');
      expect(placeTitle(_bowring), 'Bowring and Lady Curzon Hospital');
    });

    test('distances and ages read naturally', () {
      final now = DateTime(2026, 11, 21, 12);

      expect(formatDistance(450.4), '450 m');
      expect(formatDistance(1240), '1.2 km');
      expect(formatAge(now.subtract(const Duration(minutes: 12)), now), '12 min ago');
      expect(formatAge(now.subtract(const Duration(hours: 2)), now), '2 h ago');
      expect(formatAge(now.subtract(const Duration(days: 3)), now), '3 days ago');
    });
  });

  group('emergency email (issue #48)', () {
    final now = DateTime(2026, 11, 21, 14, 5);
    const here = RoutePoint(12.97633, 77.59292);

    test('the body has the time and a map link to the live position', () {
      final body = emergencyEmailBody(position: here, savedPositionTime: null, now: now);

      expect(body, contains('21 Nov 2026, 14:05'));
      expect(body, contains('https://www.openstreetmap.org/?mlat=12.97633&mlon=77.59292#map=17/12.97633/77.59292'));
      expect(body, isNot(contains('last known')));
    });

    test('with no GPS fix, it says the location is the last known one and how old it is', () {
      final body = emergencyEmailBody(
        position: here,
        savedPositionTime: now.subtract(const Duration(hours: 2)),
        now: now,
      );

      expect(body, contains('last known location'));
      expect(body, contains('2 h ago'));
      expect(body, contains('mlat=12.97633'));
    });

    test('with no location at all, it says so instead of a link', () {
      final body = emergencyEmailBody(position: null, savedPositionTime: null, now: now);

      expect(body, contains("location isn't available"));
      expect(body, isNot(contains('openstreetmap')));
    });

    test('the mailto link has the contact, subject and body, with spaces as %20', () {
      final uri = emergencyEmailUri(to: 'amma@example.com', body: 'I need help.');

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'amma@example.com');
      expect(uri.query, contains('subject=Meridian%3A%20I%20need%20help'));
      expect(uri.query, contains('body=I%20need%20help.'));
      expect(uri.query, isNot(contains('+')));
    });

    test('the contact is saved in preferences next to the interests', () async {
      final accounts = AccountsProvider();
      await accounts.loadProfile();
      await accounts.saveProfile(fullName: 'Demo', defaultCurrency: 'INR', interests: ['nature']);

      await saveEmergencyEmail(accounts.profile!, ' amma@example.com ');
      await accounts.loadProfile();

      expect(emergencyEmailOf(accounts.profile), 'amma@example.com');
      expect(accounts.interests, ['nature']);
    });

    test('a profile with no contact has none, and typos are caught', () {
      expect(emergencyEmailOf(fakeProfile), isNull);
      expect(looksLikeEmail('amma@example.com'), isTrue);
      expect(looksLikeEmail('amma@example'), isFalse);
      expect(looksLikeEmail('amma example.com'), isFalse);
    });
  });

  group('SOS screen', () {
    Future<void> show(WidgetTester tester, EmergencyProvider emergency) async {
      await tester.binding.setSurfaceSize(const Size(420, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AccountsProvider()),
          ChangeNotifierProvider.value(value: emergency),
        ],
        child: MaterialApp(theme: meridianTheme(Brightness.dark), home: const EmergencyScreen()),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('shows 112, the other helplines, the disclaimer and nearby places', (tester) async {
      await show(tester, EmergencyProvider());

      expect(find.text('Call emergency'), findsOneWidget);
      expect(find.text('112'), findsOneWidget);
      for (final number in ['100', '108', '101']) {
        expect(find.text(number), findsOneWidget);
      }
      expect(find.textContaining('not an emergency dispatch service'), findsOneWidget);
      expect(find.text('Cubbon Park Police Station'), findsOneWidget);
      expect(find.text('Unnamed hospital'), findsOneWidget);
      expect(find.textContaining('may be out of date'), findsNothing);
    });

    testWidgets('with no GPS, the stale-location warning shows', (tester) async {
      await show(tester, EmergencyProvider(currentPosition: _noGps));

      expect(find.text('Location from 12 min ago — may be out of date'), findsOneWidget);
      expect(find.text('Cubbon Park Police Station'), findsOneWidget);
    });

    testWidgets('when Overpass is down, the helplines and disclaimer stay', (tester) async {
      await show(tester, EmergencyProvider(findNearby: _overpassDown));

      expect(find.textContaining("Couldn't load nearby places"), findsOneWidget);
      expect(find.text('112'), findsOneWidget);
      expect(find.textContaining('not an emergency dispatch service'), findsOneWidget);
    });

    testWidgets('adding an emergency contact saves it to the profile', (tester) async {
      await show(tester, EmergencyProvider());
      expect(find.text('No contact saved yet.'), findsOneWidget);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'not-an-email');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Enter an email address'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'amma@example.com');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(emergencyEmailOf(fakeProfile), 'amma@example.com');
      expect(find.textContaining('To amma@example.com'), findsOneWidget);
    });
  });

  group('directions (REQ-5.2)', () {
    const here = RoutePoint(12.97633, 77.59292);

    Future<void> show(WidgetTester tester, DirectionsScreen screen) async {
      await tester.pumpWidget(MaterialApp(theme: meridianTheme(Brightness.dark), home: screen));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the route distance and time', (tester) async {
      await show(tester, const DirectionsScreen(from: here, place: _bowring, showTiles: false));

      expect(find.textContaining('min demo line'), findsOneWidget);
    });

    testWidgets('if routing fails, shows the straight-line distance without a line', (tester) async {
      Future<RouteResult> noRoute({
        required double originLat,
        required double originLng,
        required double destLat,
        required double destLng,
      }) async =>
          throw const RouteException('OSRM found no route (NoRoute)');

      await show(tester, DirectionsScreen(from: here, place: _bowring, showTiles: false, findRoute: noRoute));

      expect(find.textContaining('in a straight line · no route right now'), findsOneWidget);
    });

    testWidgets('from a saved location, it says the start may be out of date', (tester) async {
      await show(
        tester,
        const DirectionsScreen(from: here, place: _bowring, fromSavedPosition: true, showTiles: false),
      );

      expect(find.textContaining('last known location'), findsOneWidget);
    });
  });
}
