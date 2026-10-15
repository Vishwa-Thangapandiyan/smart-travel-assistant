import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_recommendations.dart';
import 'package:smart_travel_assistant/features/recommendations/add_place.dart';
import 'package:smart_travel_assistant/features/recommendations/place_photo.dart';
import 'package:smart_travel_assistant/features/recommendations/recommendations_provider.dart';

void main() {
  late RecommendationsProvider provider;

  setUp(() {
    debugUseFakeData = true;
    provider = RecommendationsProvider();
  });
  tearDown(() => debugUseFakeData = null);

  test('a destination gives its seeded places, highest rated first', () async {
    await provider.load('Bangalore');

    expect(provider.places, hasLength(13));
    expect(provider.places.every((p) => p.destination == 'Bangalore'), isTrue);
    final ratings = provider.places.map((p) => p.rating!).toList();
    expect(ratings, [...ratings]..sort((a, b) => b.compareTo(a)));
  });

  test('equal ratings are broken by name, so the order never jumps', () async {
    await provider.load('Bangalore');

    final top = provider.places.where((p) => p.rating == 4.6).map((p) => p.name).toList();
    expect(top, [...top]..sort());
  });

  test('the destination is matched without caring about capitals or spaces', () async {
    await provider.load('  jaipur ');

    expect(provider.places, hasLength(13));
  });

  test('a destination with no seeded places gives an empty list', () async {
    await provider.load('Reykjavik');

    expect(provider.places, isEmpty);
  });

  test('the category filter keeps only that category', () async {
    await provider.setCategory('restaurant');
    await provider.load('Goa');

    expect(provider.places, isNotEmpty);
    expect(provider.places.every((p) => p.category == 'restaurant'), isTrue);
  });

  test('the price filter keeps places at or under that price level', () async {
    await provider.load('Mysore');
    await provider.setMaxPrice(0);

    expect(provider.places, isNotEmpty);
    expect(provider.places.every((p) => p.priceLevel == 0), isTrue);
  });

  test('the rating filter keeps 4.5 and up', () async {
    await provider.load('Chennai');
    await provider.setMinRating(4.5);

    expect(provider.places, isNotEmpty);
    expect(provider.places.every((p) => p.rating! >= 4.5), isTrue);
  });

  test('clearing a filter brings everything back', () async {
    await provider.load('Bangalore');
    await provider.setCategory('museum');
    await provider.setCategory(null);

    expect(provider.places, hasLength(13));
  });

  test('local and old names find the seeded city', () async {
    await provider.load('Bengaluru');
    expect(provider.places, hasLength(13));

    await provider.load('mysuru');
    expect(provider.places, hasLength(12));

    await provider.load('Madras');
    expect(provider.places.first.destination, 'Chennai');

    await provider.load('Panaji');
    expect(provider.places.first.destination, 'Goa');
  });

  test('the seeded name is what the screen shows as the destination', () async {
    await provider.load('Bengaluru');

    expect(provider.destination, 'Bengaluru');
    expect(seededDestination('Bengaluru'), 'Bangalore');
    expect(seededDestination('Zurich'), 'Zurich');
  });

  test('41 destinations in India and 39 cities abroad, each with places and a cover photo', () {
    final destinations = fakeRecommendations.map((p) => p.destination).toSet();
    const some = ['Zurich', 'Tokyo', 'Kolkata', 'Leh', 'Port Blair', 'Kyoto', 'Barcelona', 'Cape Town', 'Siem Reap'];

    expect(destinations, hasLength(80));
    expect(destinations, containsAll(some));
    for (final destination in destinations) {
      final places = fakeRecommendations.where((p) => p.destination == destination);
      expect(places.length, greaterThanOrEqualTo(5), reason: destination);
      expect(cityPhotoUrl(destination), isNotNull, reason: destination);
    }
  });

  test('no place is seeded twice in the same destination', () {
    final seen = <String>{};
    for (final place in fakeRecommendations) {
      expect(seen.add('${place.destination}|${place.name}'), isTrue, reason: place.name);
    }
  });

  test('a country or an old city name finds the seeded city', () async {
    await provider.load('Switzerland');
    expect(provider.places.first.destination, 'Zurich');

    await provider.load('Bombay');
    expect(provider.places.first.destination, 'Mumbai');

    expect(seededDestination('NYC'), 'New York');
    expect(seededDestination('Cochin'), 'Kochi');
    expect(seededDestination('Calcutta'), 'Kolkata');
    expect(seededDestination('Trivandrum'), 'Thiruvananthapuram');
    expect(seededDestination('Saigon'), 'Ho Chi Minh City');
    expect(seededDestination('Vietnam'), 'Hanoi');
  });

  test('prices are rupees in India and dollar signs abroad', () {
    expect(priceLabel(0, 'Paris'), 'Free');
    expect(priceLabel(2, 'Jaipur'), '₹₹');
    expect(priceLabel(3, 'Tokyo'), r'$$$');
    expect(priceLabel(1, 'Leh'), '₹');
    expect(priceLabel(2, 'Kyoto'), r'$$');
  });
}
