// Owner: Vishwa. One recommended place in full (REQ-6.1): its photo with
// the name over it, the facts, a small map, and Add to a day (REQ-6.3).
// Opened by tapping a card on Explore. Design: DESIGN.md §7, "Place".

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/recommendation.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import '../itinerary/itinerary_provider.dart';
import '../maps/maps_screen.dart';
import 'add_place.dart';
import 'place_categories.dart';
import 'place_photo.dart';

class PlaceDetailScreen extends StatelessWidget {
  final Recommendation place;

  /// Set when Explore was opened from a Day screen: Add goes straight there.
  final int? addToDay;

  /// Off in tests, which have no network for map tiles.
  final bool showTiles;

  const PlaceDetailScreen({super.key, required this.place, this.addToDay, this.showTiles = true});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final itinerary = context.watch<ItineraryProvider>();
    final trip = itinerary.currentTrip;
    final addedOn = trip == null ? null : addedOnLabel(place, trip, itinerary);
    final photoPage = place.imageUrl == null ? null : photoSourcePage(place.imageUrl!);
    final facts = [
      (placeCategories[place.category] ?? place.category).toUpperCase(),
      if (place.rating != null) '★ ${place.rating}',
      if (place.priceLevel != null) priceLabel(place.priceLevel!, place.destination),
    ].join('  ·  ');

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlacePhoto(place: place, iconSize: 72),
                    // The photo fades into the page, so the name on it stays readable.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.35, 1],
                          colors: [colors.ground.withValues(alpha: 0), colors.ground],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place.destination.toUpperCase(),
                              style: MeridianText.monoData.copyWith(color: colors.inkSoft, letterSpacing: 2)),
                          const SizedBox(height: 6),
                          Text(place.name, style: MeridianText.monoDisplay.copyWith(color: colors.ink)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(facts, style: MeridianText.monoData.copyWith(color: colors.amberText, fontSize: 13)),
                    if (place.description != null) ...[
                      const SizedBox(height: 16),
                      Text(place.description!, style: text.bodyLarge?.copyWith(fontSize: 17)),
                    ],
                    if (place.tags?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final tag in place.tags!) _Tag(tag)],
                      ),
                    ],
                    if (place.latitude != null && place.longitude != null) ...[
                      const SizedBox(height: 28),
                      Text('WHERE IT IS', style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
                      const SizedBox(height: 8),
                      _SmallMap(point: LatLng(place.latitude!, place.longitude!), showTiles: showTiles),
                    ],
                    const SizedBox(height: 28),
                    if (trip == null)
                      Text('Create a trip on the Trips tab to add this place to a day.',
                          style: text.bodyMedium?.copyWith(color: colors.inkSoft))
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => addPlaceToTrip(context, place, trip, day: addToDay),
                          icon: const Icon(Icons.add),
                          label: Text(addToDay == null ? 'Add to a day' : 'Add to Day $addToDay'),
                        ),
                      ),
                    if (addedOn != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text('$addedOn ✓', style: MeridianText.monoData.copyWith(color: colors.green)),
                      ),
                    ],
                    if (photoPage != null) ...[
                      const SizedBox(height: 16),
                      // Licence condition: credit the photo; its Commons page names the author.
                      TextButton.icon(
                        onPressed: () => launchUrl(photoPage, mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Photo: Wikimedia Commons'),
                        style: TextButton.styleFrom(foregroundColor: colors.inkSoft, padding: EdgeInsets.zero),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filled(
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: colors.ground.withValues(alpha: 0.7),
                  foregroundColor: colors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
    );
  }
}

/// A fixed map with one pin: shows where the place is, nothing to pan.
class _SmallMap extends StatelessWidget {
  final LatLng point;
  final bool showTiles;

  const _SmallMap({required this.point, required this.showTiles});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final night = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                backgroundColor: colors.surface,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                if (showTiles)
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.meridian.smart_travel_assistant',
                    tileBuilder: night ? (context, tile, _) => ColorFiltered(colorFilter: nightTiles, child: tile) : null,
                  ),
                MarkerLayer(markers: [
                  Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: Icon(Icons.location_on, size: 40, color: colors.amber),
                  ),
                ]),
              ],
            ),
            // Licence condition: OpenStreetMap credit on every map.
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                color: colors.ground.withValues(alpha: 0.7),
                child: Text('© OpenStreetMap contributors',
                    style: MeridianText.monoData.copyWith(fontSize: 10, color: colors.inkSoft)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
