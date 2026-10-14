// Owner: Vishwa. The first tab: the next trip as a big photo card with days
// to go, then later and past trips as rows, and + to create one (REQ-2.1).
// Design: DESIGN.md §7, "Trips". A city Explore doesn't cover has no photo,
// so its card is the plain inverted (cream by night) card instead.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/trip.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import '../../widgets/web_photo.dart';
import '../accounts/account_sheet.dart';
import '../accounts/accounts_provider.dart';
import '../recommendations/place_photo.dart' show cityPhotoUrl;
import 'destination_lookup.dart';
import 'itinerary_provider.dart';
import 'new_trip_screen.dart';
import 'day_screen.dart';
import 'trip_dates.dart';

class TripsScreen extends StatefulWidget {
  /// Tests pass a stand-in; the app uses Nominatim.
  final LookUpDestination? lookUp;

  const TripsScreen({super.key, this.lookUp});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AccountsProvider>().userId;
    if (userId == null) return;
    try {
      await context.read<ItineraryProvider>().loadTrips(userId);
      if (mounted) setState(() => _loadError = null);
    } on Exception {
      if (mounted) setState(() => _loadError = 'Couldn\'t load your trips. Check your connection.');
    }
  }

  void _openTrip(Trip trip) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DayScreen(trip: trip, lookUp: widget.lookUp ?? lookUpDestination),
    ));
  }

  Future<void> _newTrip() async {
    final created = await Navigator.of(context).push<Trip>(
      MaterialPageRoute(
        builder: (_) => NewTripScreen(lookUp: widget.lookUp ?? lookUpDestination),
      ),
    );
    if (created != null && mounted) _openTrip(created);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final trips = context.watch<ItineraryProvider>().trips;

    final today = DateTime.now();
    final upcoming = nextTrip(trips, today: today);
    final later = trips.where((t) => t != upcoming && daysUntil(t.endDate, today: today) >= 0).toList();
    // Most recent first: the trip you just came back from is the one you look for.
    final done = trips.where((t) => daysUntil(t.endDate, today: today) < 0).toList().reversed.toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Row(
            children: [
              Expanded(child: Text('Trips', style: text.headlineMedium)),
              IconButton(
                tooltip: 'Account',
                onPressed: () => showAccountSheet(context),
                icon: const Icon(Icons.person_outline),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'New trip',
                onPressed: _newTrip,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  minimumSize: const Size(52, 52),
                  backgroundColor: colors.ink,
                  foregroundColor: colors.ground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loadError != null) ...[
            Text(_loadError!, style: text.bodyMedium?.copyWith(color: colors.coral)),
            const SizedBox(height: 16),
          ],
          if (trips.isEmpty && _loadError == null) _NoTrips(onPlan: _newTrip),
          if (upcoming != null) _NextTripCard(trip: upcoming, today: today, onTap: () => _openTrip(upcoming)),
          if (later.isNotEmpty) ...[
            const _SectionLabel('LATER'),
            for (final trip in later) _TripRow(trip: trip, done: false, onTap: () => _openTrip(trip)),
          ],
          if (done.isNotEmpty) ...[
            const _SectionLabel('DONE'),
            for (final trip in done) _TripRow(trip: trip, done: true, onTap: () => _openTrip(trip)),
          ],
        ],
      ),
    );
  }
}

/// The next trip, poster-style: the city's photo filling a tall card, the
/// name in big mono over it, and the days to go in the corner.
class _NextTripCard extends StatelessWidget {
  final Trip trip;
  final DateTime today;
  final VoidCallback onTap;

  const _NextTripCard({required this.trip, required this.today, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final photo = cityPhotoUrl(trip.destination);
    final days = daysUntil(trip.startDate, today: today);

    // On a photo the text is always the night palette's light ink over a
    // dark fade, in both modes, so it reads on any photo. Without a photo
    // the card is simply inverted: ink background, ground-coloured text.
    const night = MeridianColors.night;
    final ink = photo == null ? colors.ground : night.ink;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 420,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo == null)
              ColoredBox(color: colors.ink)
            else ...[
              WebPhoto(url: photo, placeholder: ColoredBox(color: night.ember)),
              // Dark at the top for the days to go, clear in the middle,
              // dark again at the bottom for the name.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.3, 0.5, 1],
                    colors: [
                      night.ground.withValues(alpha: 0.55),
                      night.ground.withValues(alpha: 0),
                      night.ground.withValues(alpha: 0),
                      night.ground.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text('NEXT TRIP', style: MeridianText.monoData.copyWith(color: ink, letterSpacing: 2)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(days > 0 ? '$days' : '${1 - days}/${trip.numberOfDays}',
                              style: MeridianText.nowNumber.copyWith(color: ink)),
                          const SizedBox(height: 6),
                          Text(days > 0 ? 'DAYS TO GO' : 'DAY · ON NOW',
                              style: MeridianText.monoData.copyWith(color: ink)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(trip.destination, style: MeridianText.monoDisplay.copyWith(color: ink)),
                  const SizedBox(height: 8),
                  Text('${tripDateRange(trip)} · ${trip.numberOfDays} days'.toUpperCase(),
                      style: MeridianText.monoData.copyWith(color: ink)),
                ],
              ),
            ),
            // On top of everything, so the whole card is one tap target.
            Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown before the first trip: one clear way to start.
class _NoTrips extends StatelessWidget {
  final VoidCallback onPlan;

  const _NoTrips({required this.onPlan});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colors.ember, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where to next?', style: MeridianText.monoDisplay.copyWith(color: colors.ink)),
          const SizedBox(height: 12),
          Text('Plan a trip, then add each day\'s stops yourself.',
              style: text.bodyLarge?.copyWith(color: colors.inkSoft)),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: onPlan, icon: const Icon(Icons.add), label: const Text('Plan a trip')),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 4),
      child: Text(label, style: MeridianText.monoData.copyWith(color: colors.inkSoft, letterSpacing: 2)),
    );
  }
}

/// A later or past trip: the city's photo small, name, and its dates.
class _TripRow extends StatelessWidget {
  final Trip trip;
  final bool done;
  final VoidCallback onTap;

  const _TripRow({required this.trip, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;

    final row = InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox.square(
                dimension: 64,
                child: WebPhoto(
                  url: cityPhotoUrl(trip.destination),
                  placeholder: Container(
                    color: colors.ember,
                    alignment: Alignment.center,
                    child: Text(trip.destination.characters.first.toUpperCase(),
                        style: MeridianText.monoHeading.copyWith(color: colors.inkSoft)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.destination, style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    done ? '${DateFormat('MMM yyyy').format(trip.startDate)} · done'.toUpperCase() : tripDateRange(trip).toUpperCase(),
                    style: MeridianText.monoData.copyWith(color: colors.inkSoft),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.inkSoft),
          ],
        ),
      ),
    );

    // Past trips step back so the ones ahead stand out.
    return done ? Opacity(opacity: 0.6, child: row) : row;
  }
}
