import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_data.dart';
import 'package:smart_travel_assistant/features/itinerary/itinerary_provider.dart';
import 'package:smart_travel_assistant/services/trip_service.dart';

List<String> _titles(ItineraryProvider provider, int day) =>
    provider.stopsForDay(day).map((s) => s.title).toList();

void main() {
  late ItineraryProvider provider;

  setUp(() async {
    debugUseFakeData = true;
    resetFakeTrips();
    provider = ItineraryProvider();
    await provider.openTrip(demoTrip);
  });
  tearDown(() => debugUseFakeData = null);

  test('opening a trip loads its stops, day by day, in order', () {
    expect(_titles(provider, 2), [
      'MTR, Lalbagh Road',
      'Lalbagh Botanical Garden',
      'Bangalore Palace',
      'Cubbon Park',
      'Church Street',
    ]);
  });

  test('a new stop goes to the end of its day and is saved', () async {
    await provider.addStop(
      day: 2,
      title: 'Vidhana Soudha',
      locationName: 'Vidhana Soudha, Bengaluru',
      latitude: 12.9796,
      longitude: 77.5907,
      startTime: '17:30:00',
      notes: 'Lit up after dark',
    );

    expect(_titles(provider, 2).last, 'Vidhana Soudha');
    // Day 1 already has a Vidhana Soudha stop, so look on day 2 only.
    final saved = (await getItineraryItems(demoTrip.id))
        .where((i) => i.dayNumber == 2 && i.title == 'Vidhana Soudha');
    expect(saved.single.notes, 'Lit up after dark');
    expect(saved.single.latitude, 12.9796);
  });

  test('the first stop on an empty day gets position 0', () async {
    final goa = await provider.createTrip(
      userId: demoUserId,
      destination: 'Goa',
      start: DateTime(2027, 1, 10),
      end: DateTime(2027, 1, 11),
      match: null,
    );
    await provider.openTrip(goa);

    await provider.addStop(day: 1, title: 'Fontainhas');

    expect(provider.stopsForDay(1).single.orderIndex, 0);
    expect(provider.stopsForDay(2), isEmpty);
  });

  test('editing a stop changes its title, time and notes', () async {
    final palace = provider.stopsForDay(2)[2];

    await provider.updateStop(palace,
        title: 'Bangalore Palace (tour)', startTime: '13:00:00', notes: 'Audio tour at the gate');

    final edited = provider.stopsForDay(2)[2];
    expect(edited.id, palace.id);
    expect(edited.title, 'Bangalore Palace (tour)');
    expect(edited.startTime, '13:00:00');
    expect(edited.notes, 'Audio tour at the gate');
  });

  test('a note can be cleared again', () async {
    final park = provider.stopsForDay(2)[3];

    await provider.updateStop(park, title: park.title, notes: null);

    expect(provider.stopsForDay(2)[3].notes, isNull);
  });

  test('deleting a stop removes it from its day and from storage', () async {
    final park = provider.stopsForDay(2)[3];

    await provider.deleteStop(park);

    expect(_titles(provider, 2), isNot(contains('Cubbon Park')));
    expect((await getItineraryItems(demoTrip.id)).map((i) => i.id), isNot(contains(park.id)));
  });

  test('moving a stop up swaps it with the one above', () async {
    await provider.moveStop(provider.stopsForDay(2)[2], up: true);

    expect(_titles(provider, 2).sublist(1, 3), ['Bangalore Palace', 'Lalbagh Botanical Garden']);
  });

  test('moving a stop down swaps it with the one below, and survives a reload', () async {
    await provider.moveStop(provider.stopsForDay(2)[0], up: false);
    await provider.openTrip(demoTrip);

    expect(_titles(provider, 2).sublist(0, 2), ['Lalbagh Botanical Garden', 'MTR, Lalbagh Road']);
  });

  test('the first stop cannot move up and the last cannot move down', () async {
    final before = _titles(provider, 2);

    await provider.moveStop(provider.stopsForDay(2).first, up: true);
    await provider.moveStop(provider.stopsForDay(2).last, up: false);

    expect(_titles(provider, 2), before);
  });

  test('stops on other days are never touched', () async {
    final day1 = _titles(provider, 1);

    await provider.moveStop(provider.stopsForDay(2)[1], up: true);
    await provider.deleteStop(provider.stopsForDay(2).last);

    expect(_titles(provider, 1), day1);
  });
}
