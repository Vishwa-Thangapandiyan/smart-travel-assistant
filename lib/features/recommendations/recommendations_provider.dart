// Owner: Vishwa. The Explore feed: places for a trip's destination from
// the hand-seeded `recommendations` table, filtered and ranked by the
// database query itself — ORDER BY rating, then name (REQ-6.1, 6.2, 6.4).
// This is a plain sort, not a model; nothing here learns or predicts.
// Registered in lib/main.dart.

import 'package:flutter/foundation.dart';

import '../../dev/app_config.dart';
import '../../dev/fake_recommendations.dart';
import '../../models/recommendation.dart';
import '../../services/supabase_service.dart';

// Other names people type for the seeded cities. A trip saved as
// "Bengaluru" should still find the places seeded under "Bangalore".
// A country's name finds the one city seeded for it.
const _otherNames = {
  'bengaluru': 'Bangalore',
  'mysuru': 'Mysore',
  'madras': 'Chennai',
  'panaji': 'Goa',
  'panjim': 'Goa',
  'pink city': 'Jaipur',
  'new delhi': 'Delhi',
  'old delhi': 'Delhi',
  'bombay': 'Mumbai',
  'benares': 'Varanasi',
  'banaras': 'Varanasi',
  'kashi': 'Varanasi',
  'cochin': 'Kochi',
  'ernakulam': 'Kochi',
  'fort kochi': 'Kochi',
  'england': 'London',
  'uk': 'London',
  'united kingdom': 'London',
  'france': 'Paris',
  'italy': 'Rome',
  'roma': 'Rome',
  'switzerland': 'Zurich',
  'zürich': 'Zurich',
  'uae': 'Dubai',
  'united arab emirates': 'Dubai',
  'thailand': 'Bangkok',
  'indonesia': 'Bali',
  'japan': 'Tokyo',
  'usa': 'New York',
  'united states': 'New York',
  'new york city': 'New York',
  'nyc': 'New York',
  'secunderabad': 'Hyderabad',
  'calcutta': 'Kolkata',
  'poona': 'Pune',
  'amdavad': 'Ahmedabad',
  'simla': 'Shimla',
  'udhagamandalam': 'Ooty',
  'ootacamund': 'Ooty',
  'alleppey': 'Alappuzha',
  'pondicherry': 'Puducherry',
  'pondy': 'Puducherry',
  'mamallapuram': 'Mahabalipuram',
  'ladakh': 'Leh',
  'kashmir': 'Srinagar',
  'sikkim': 'Gangtok',
  'meghalaya': 'Shillong',
  'kodagu': 'Coorg',
  'madikeri': 'Coorg',
  'trivandrum': 'Thiruvananthapuram',
  'kanniyakumari': 'Kanyakumari',
  'cape comorin': 'Kanyakumari',
  'chhatrapati sambhajinagar': 'Aurangabad',
  'sambhajinagar': 'Aurangabad',
  'sri vijaya puram': 'Port Blair',
  'andaman': 'Port Blair',
  'andaman and nicobar islands': 'Port Blair',
  'spain': 'Barcelona',
  'catalonia': 'Barcelona',
  'netherlands': 'Amsterdam',
  'holland': 'Amsterdam',
  'germany': 'Berlin',
  'czechia': 'Prague',
  'czech republic': 'Prague',
  'praha': 'Prague',
  'austria': 'Vienna',
  'wien': 'Vienna',
  'turkey': 'Istanbul',
  'türkiye': 'Istanbul',
  'turkiye': 'Istanbul',
  'greece': 'Athens',
  'egypt': 'Cairo',
  'south korea': 'Seoul',
  'korea': 'Seoul',
  'australia': 'Sydney',
  'malaysia': 'Kuala Lumpur',
  'kl': 'Kuala Lumpur',
  'vietnam': 'Hanoi',
  'viet nam': 'Hanoi',
  'ha noi': 'Hanoi',
  'saigon': 'Ho Chi Minh City',
  'hcmc': 'Ho Chi Minh City',
  'nepal': 'Kathmandu',
  'sri lanka': 'Colombo',
  'sf': 'San Francisco',
  'la': 'Los Angeles',
  'canada': 'Toronto',
  'portugal': 'Lisbon',
  'lisboa': 'Lisbon',
  'venezia': 'Venice',
  'firenze': 'Florence',
  'scotland': 'Edinburgh',
  'south africa': 'Cape Town',
  'cambodia': 'Siem Reap',
};

/// The name the places are seeded under, or [destination] itself if it
/// isn't a known other name.
String seededDestination(String destination) {
  final trimmed = destination.trim();
  return _otherNames[trimmed.toLowerCase()] ?? trimmed;
}

class RecommendationsProvider extends ChangeNotifier {
  String? _destination;
  String? get destination => _destination;

  // Filters; null means "any".
  String? _category;
  String? get category => _category;
  int? _maxPrice;
  int? get maxPrice => _maxPrice;
  double? _minRating;
  double? get minRating => _minRating;

  List<Recommendation> _places = [];
  List<Recommendation> get places => _places;

  Future<void> load(String destination) async {
    _destination = destination.trim();
    await _query();
  }

  Future<void> setCategory(String? category) async {
    _category = category;
    await _query();
  }

  Future<void> setMaxPrice(int? maxPrice) async {
    _maxPrice = maxPrice;
    await _query();
  }

  Future<void> setMinRating(double? minRating) async {
    _minRating = minRating;
    await _query();
  }

  Future<void> _query() async {
    if (_destination == null) return;
    final destination = seededDestination(_destination!);

    if (useFakeData) {
      _places = _fakeQuery(destination);
    } else {
      // ilike without wildcards: the same name, ignoring capitals.
      var query = supabaseClient.from('recommendations').select().ilike('destination', destination);
      if (_category != null) query = query.eq('category', _category!);
      if (_maxPrice != null) query = query.lte('price_level', _maxPrice!);
      if (_minRating != null) query = query.gte('rating', _minRating!);
      final rows = await query.order('rating', ascending: false).order('name');
      _places = rows.map(Recommendation.fromJson).toList();
    }
    notifyListeners();
  }

  // The same filters and ORDER BY as the real query, over the seed rows.
  List<Recommendation> _fakeQuery(String destination) {
    final places = fakeRecommendations.where((p) {
      if (p.destination.toLowerCase() != destination.toLowerCase()) return false;
      if (_category != null && p.category != _category) return false;
      if (_maxPrice != null && (p.priceLevel == null || p.priceLevel! > _maxPrice!)) return false;
      if (_minRating != null && (p.rating == null || p.rating! < _minRating!)) return false;
      return true;
    }).toList();
    places.sort((a, b) {
      final byRating = (b.rating ?? 0).compareTo(a.rating ?? 0);
      return byRating != 0 ? byRating : a.name.compareTo(b.name);
    });
    return places;
  }
}
