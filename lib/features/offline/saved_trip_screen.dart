// Owner: Sanjay. The downloaded copy of a trip, read-only, from Hive
// (REQ-4.3): itinerary, guide text and the one saved map picture with each
// day's route, always under the "Offline — showing saved data" banner. The app opens it when
// Supabase can't be reached; it needs no signal at all.
//
// Editing offline is not decided by the team (PROJECT-UNDERSTANDING.md
// Part 8), so nothing here can be changed.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/itinerary_item.dart';
import '../../services/offline_service.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import '../maps/maps_screen.dart' show nightTiles;
import '../itinerary/stays_provider.dart';
import '../maps/navigate.dart';

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
    // Navigate to the day's first placed stop starts at the stay, if any.
    final firstPlaced = stops.indexWhere((s) => s.latitude != null && s.longitude != null);

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
              if (stops[i].latitude != null && stops[i].longitude != null)
                IconButton(
                  tooltip: 'Navigate',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.navigation_outlined, color: colors.amberText),
                  onPressed: () => openDirections(
                    stops[i].latitude!,
                    stops[i].longitude!,
                    from: i == firstPlaced ? context.read<StaysProvider>().stayFor(saved.trip.id) : null,
                  ),
                ),
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

/// The saved map of one day: its OpenStreetMap tiles laid side by side as
/// one picture, with the day's route and numbered stops drawn on top
/// (issue #59). Chips switch between the days that have a placed stop. A picture, not a map: it doesn't pan or zoom, and it says so.
class _SavedMap extends StatefulWidget {
  final SavedTrip saved;

  const _SavedMap({required this.saved});

  @override
  State<_SavedMap> createState() => _SavedMapState();
}

class _SavedMapState extends State<_SavedMap> {
  int _day = 1;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final saved = widget.saved;
    if (saved.mapAreas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16)),
        child: Text('No map was saved with this trip. Download it again while online to get one.', style: text.bodySmall),
      );
    }

    final days = saved.mapAreas.keys.toList()..sort();
    final day = days.contains(_day) ? _day : days.first;
    final area = saved.mapAreas[day]!;
    final tiles = area.tiles;
    final hasTiles = tiles.every((tile) => saved.mapTiles.containsKey(tile.url));
    final stops = saved.items.where((i) => i.dayNumber == day).toList();
    final route = saved.routes[day] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (days.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in days)
                ChoiceChip(
                  label: Text('Day $chip'),
                  selected: chip == day,
                  onSelected: (_) => setState(() => _day = chip),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(builder: (context, box) {
              final side = box.maxWidth;
              Offset? onMap(double latitude, double longitude) {
                final spot = area.positionOf(latitude, longitude);
                return spot == null ? null : Offset(spot.across * side, spot.down * side);
              }

              // The tiles as one picture, tinted like the live map at night.
              Widget? picture;
              if (hasTiles) {
                picture = Stack(
                  children: [
                    for (final tile in tiles)
                      Positioned(
                        left: tile.across * side,
                        top: tile.down * side,
                        // A hair bigger than a tile, so no seam shows between neighbours.
                        width: side / StaticMapArea.size + 0.5,
                        height: side / StaticMapArea.size + 0.5,
                        child: Image.memory(saved.mapTiles[tile.url]!, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
                      ),
                  ],
                );
                if (Theme.of(context).brightness == Brightness.dark) {
                  picture = ColorFiltered(colorFilter: nightTiles, child: picture);
                }
              }

              return Semantics(
                label: 'Saved map of ${saved.trip.destination}, day $day',
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: colors.surface)),
                    if (picture != null) Positioned.fill(child: picture),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RouteLine(
                          points: [for (final point in route) onMap(point.latitude, point.longitude)].nonNulls.toList(),
                          color: colors.amber,
                        ),
                      ),
                    ),
                    for (var i = 0; i < stops.length; i++)
                      if (stops[i].latitude != null && stops[i].longitude != null)
                        if (onMap(stops[i].latitude!, stops[i].longitude!) case final spot?)
                          Positioned(left: spot.dx - 13, top: spot.dy - 13, child: _StopNumber(number: i + 1)),
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
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasTiles
              ? "Saved map picture — it doesn't move or zoom. New routes need signal."
              : "The map tiles didn't download, so this shows the stops and route only.",
          style: text.bodySmall,
        ),
      ],
    );
  }
}

/// A stop's number in a circle, the same look as the Map tab's pins.
class _StopNumber extends StatelessWidget {
  final int number;

  const _StopNumber({required this.number});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(color: colors.ink, width: 2),
      ),
      child: Text('$number', style: MeridianText.monoData.copyWith(color: colors.ink, fontSize: 12)),
    );
  }
}

/// The day's road route as one line through the saved points.
class _RouteLine extends CustomPainter {
  final List<Offset> points;
  final Color color;

  const _RouteLine({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_RouteLine old) => old.points != points || old.color != color;
}
