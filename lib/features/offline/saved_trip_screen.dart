// Owner: Sanjay. The downloaded copy of a trip, read-only, from Hive
// (REQ-4.3): itinerary, guide text and the one saved map image, always
// under the "Offline — showing saved data" banner. The app opens it when
// Supabase can't be reached; it needs no signal at all.
//
// Editing offline is not decided by the team (PROJECT-UNDERSTANDING.md
// Part 8), so nothing here can be changed.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/itinerary_item.dart';
import '../../services/offline_service.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';

class SavedTripScreen extends StatefulWidget {
  final String tripId;

  const SavedTripScreen({super.key, required this.tripId});

  @override
  State<SavedTripScreen> createState() => _SavedTripScreenState();
}

class _SavedTripScreenState extends State<SavedTripScreen> {
  late final Future<SavedTrip?> _saved = loadSavedTrip(widget.tripId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved trip')),
      body: FutureBuilder<SavedTrip?>(
        future: _saved,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final saved = snapshot.data;
          if (saved == null) return const _NeverDownloaded();
          return _SavedTripView(saved: saved);
        },
      ),
    );
  }
}

/// A trip opened offline that was never downloaded: say so, not a blank screen.
class _NeverDownloaded extends StatelessWidget {
  const _NeverDownloaded();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, size: 40, color: Theme.of(context).extension<MeridianColors>()!.inkSoft),
          const SizedBox(height: 16),
          Text("This trip isn't saved on this phone", style: text.headlineMedium),
          const SizedBox(height: 8),
          Text(
            "There's no signal and this trip was never downloaded, so there's nothing to show. "
            "Next time you're online, open the trip and tap \"Download for offline\".",
            style: text.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _SavedTripView extends StatelessWidget {
  final SavedTrip saved;

  const _SavedTripView({required this.saved});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final trip = saved.trip;
    final dates = '${DateFormat('d MMM').format(trip.startDate)} – ${DateFormat('d MMM yyyy').format(trip.endDate)}';

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.paddingOf(context).bottom + 24),
      children: [
        _OfflineBanner(downloadedAt: saved.downloadedAt),
        const SizedBox(height: 20),
        Text(trip.destination, style: text.headlineMedium),
        const SizedBox(height: 4),
        Text(dates.toUpperCase(), style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
        const SizedBox(height: 20),
        _SavedMap(saved: saved),
        const SizedBox(height: 24),
        Text('Guide', style: text.titleLarge),
        const SizedBox(height: 8),
        Text(saved.guideText ?? 'No guide was saved for ${trip.destination}.', style: text.bodyLarge),
        for (var day = 1; day <= trip.numberOfDays; day++)
          ..._daySection(context, day, saved.items.where((i) => i.dayNumber == day).toList()),
      ],
    );
  }

  List<Widget> _daySection(BuildContext context, int day, List<ItineraryItem> stops) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final date = saved.trip.startDate.add(Duration(days: day - 1));

    return [
      const SizedBox(height: 24),
      Text('Day $day · ${DateFormat('EEEE, d MMM').format(date)}', style: MeridianText.monoHeading.copyWith(color: colors.ink)),
      const SizedBox(height: 8),
      if (stops.isEmpty) Text('No stops planned.', style: text.bodySmall),
      for (var i = 0; i < stops.length; i++)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.line))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text('${i + 1}', style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stops[i].title, style: text.titleLarge?.copyWith(fontSize: 16)),
                    if (stops[i].notes != null && stops[i].notes!.isNotEmpty) Text(stops[i].notes!, style: text.bodySmall),
                  ],
                ),
              ),
              if (stops[i].startTime != null)
                Text(stops[i].startTime!.substring(0, 5), style: MeridianText.monoData.copyWith(color: colors.ink)),
            ],
          ),
        ),
    ];
  }
}

/// Shown whenever saved data is on screen, with how old the copy is.
class _OfflineBanner extends StatelessWidget {
  final DateTime downloadedAt;

  const _OfflineBanner({required this.downloadedAt});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.green.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.offline_pin_outlined, size: 18, color: colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline — showing saved data · saved ${DateFormat('d MMM, HH:mm').format(downloadedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// The one saved map image with the stops that fall on it. A picture, not
/// a map: it doesn't pan or zoom, and it says so.
class _SavedMap extends StatelessWidget {
  final SavedTrip saved;

  const _SavedMap({required this.saved});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final image = saved.mapImage;
    final tile = staticMapTileFor(saved.trip, saved.items);

    if (image == null || tile == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16)),
        child: Text('No map image was saved with this trip.', style: text.bodySmall),
      );
    }

    // A dot for every stop that falls on the image; stops off it are skipped.
    final spots = [
      for (final stop in saved.items)
        if (stop.latitude != null && stop.longitude != null) tile.positionOf(stop.latitude!, stop.longitude!),
    ].nonNulls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                children: [
                  Positioned.fill(
                    child: Semantics(
                      label: 'Saved map of ${saved.trip.destination}',
                      child: Image.memory(image, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
                    ),
                  ),
                  for (final spot in spots)
                    Positioned(
                      left: spot.across * box.maxWidth - 9,
                      top: spot.down * box.maxHeight - 9,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.amber,
                          border: Border.all(color: colors.ground, width: 2),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
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
          ),
        ),
        const SizedBox(height: 6),
        Text('Saved map image — it doesn\'t move or zoom. New routes need signal.', style: text.bodySmall),
      ],
    );
  }
}
