// Owner: Vishwa. The Explore tab: places worth a look in the open trip's
// destination, highest rated first, with category, price and rating
// filters (REQ-6.1, 6.2, 6.4). + adds a place to a day of the trip as a
// stop (REQ-6.3); tapping a card opens the place. Opened from a Day
// screen's "From suggestions", + adds straight to that day.
// Design: design/screens/night-06-explore.png.
// The ranking is a database sort — never call it AI or smart picks.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recommendation.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import '../accounts/accounts_provider.dart';
import '../itinerary/itinerary_provider.dart';
import 'add_place.dart';
import 'place_categories.dart';
import 'place_detail_screen.dart';
import 'place_photo.dart';
import 'recommendations_provider.dart';

class RecommendationsScreen extends StatefulWidget {
  /// Set when opened from a Day screen: + adds straight to this day.
  final int? addToDay;

  const RecommendationsScreen({super.key, this.addToDay});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  @override
  void initState() {
    super.initState();
    _openNextTripIfNone();
  }

  Future<void> _openNextTripIfNone() async {
    final userId = context.read<AccountsProvider>().userId;
    if (userId == null) return;
    try {
      await context.read<ItineraryProvider>().openNextTripIfNone(userId);
    } on Exception {
      // No trips loaded: the screen says there is no trip.
    }
  }

  Future<void> _filter(Future<void> Function() change) async {
    try {
      await change();
    } on Exception {
      _say('Couldn\'t load places. Check your connection.');
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final itinerary = context.watch<ItineraryProvider>();
    final feed = context.watch<RecommendationsProvider>();
    final trip = itinerary.currentTrip;

    // Load (or reload) the feed when the open trip's destination changes.
    if (trip != null && trip.destination.trim() != feed.destination) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _filter(() => feed.load(trip.destination));
      });
    }

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        if (trip == null)
          Text('Create a trip on the Trips tab to see places worth a look.',
              style: text.bodyLarge?.copyWith(color: colors.inkSoft))
        else ...[
          Text('Worth a look in', style: text.bodyMedium?.copyWith(color: colors.inkSoft)),
          Text(trip.destination, style: MeridianText.monoHeading.copyWith(fontSize: 36, color: colors.ink)),
          const SizedBox(height: 16),
          _ChipRow(children: [
            _Chip(label: 'All', selected: feed.category == null, onTap: () => _filter(() => feed.setCategory(null))),
            for (final entry in placeCategories.entries)
              _Chip(
                label: entry.value,
                selected: feed.category == entry.key,
                onTap: () => _filter(() => feed.setCategory(entry.key)),
              ),
          ]),
          const SizedBox(height: 8),
          _ChipRow(children: [
            _Chip(
              label: 'Free',
              selected: feed.maxPrice == 0,
              onTap: () => _filter(() => feed.setMaxPrice(feed.maxPrice == 0 ? null : 0)),
            ),
            _Chip(
              label: '₹ and under',
              selected: feed.maxPrice == 1,
              onTap: () => _filter(() => feed.setMaxPrice(feed.maxPrice == 1 ? null : 1)),
            ),
            _Chip(
              label: '★ 4.5 and up',
              selected: feed.minRating == 4.5,
              onTap: () => _filter(() => feed.setMinRating(feed.minRating == 4.5 ? null : 4.5)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('${feed.places.length} ${feed.places.length == 1 ? 'PLACE' : 'PLACES'}',
                    style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
              ),
              Text('HIGHEST RATED FIRST', style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
            ],
          ),
          const SizedBox(height: 12),
          if (feed.places.isEmpty)
            Text(
              feed.category == null && feed.maxPrice == null && feed.minRating == null
                  ? 'No suggestions for ${trip.destination} yet. Explore covers 13 destinations in India '
                      'and one city in each of 10 countries. You can still add any place to a day by hand.'
                  : 'Nothing matches these filters.',
              style: text.bodyMedium?.copyWith(color: colors.inkSoft),
            ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.62,
            children: [
              for (final place in feed.places)
                _PlaceCard(
                  place: place,
                  addedOn: addedOnLabel(place, trip, itinerary),
                  onAdd: () => addPlaceToTrip(context, place, trip, day: widget.addToDay),
                  onOpen: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PlaceDetailScreen(place: place, addToDay: widget.addToDay),
                  )),
                ),
            ],
          ),
        ],
      ],
    );

    if (widget.addToDay == null) return SafeArea(child: body);
    return Scaffold(
      appBar: AppBar(title: Text('Add to Day ${widget.addToDay}')),
      body: body,
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<Widget> children;

  const _ChipRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [for (final chip in children) Padding(padding: const EdgeInsets.only(right: 8), child: chip)]),
    );
  }
}

/// A pill filter: cream when selected, outlined otherwise.
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        backgroundColor: selected ? colors.ink : Colors.transparent,
        foregroundColor: selected ? colors.ground : colors.ink,
        side: BorderSide(color: selected ? colors.ink : colors.line),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(label),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Recommendation place;
  final String? addedOn;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  const _PlaceCard({required this.place, required this.addedOn, required this.onAdd, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final facts = [
      placeCategories[place.category] ?? place.category,
      if (place.rating != null) '★ ${place.rating}',
      if (place.priceLevel != null) priceLabel(place.priceLevel!, place.destination),
    ].join(' · ');

    return GestureDetector(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(borderRadius: BorderRadius.circular(20), child: PlacePhoto(place: place)),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    tooltip: 'Add ${place.name}',
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(backgroundColor: colors.amber, foregroundColor: colors.onAmber),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(place.name, style: text.titleLarge?.copyWith(fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(facts, style: MeridianText.monoData.copyWith(color: colors.inkSoft, fontSize: 11)),
          if (addedOn != null)
            Text('$addedOn ✓', style: MeridianText.monoData.copyWith(color: colors.green, fontSize: 11)),
        ],
      ),
    );
  }
}
