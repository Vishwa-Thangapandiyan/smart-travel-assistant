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
    final destination = _destination;
    if (destination == null) return;

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
