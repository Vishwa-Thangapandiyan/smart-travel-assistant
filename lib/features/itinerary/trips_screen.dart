// Owner: Vishwa. The first tab: the next trip as a cream card with days to
// go, other trips as rows, and + to create one (REQ-2.1).
// Design: design/screens/night-02-trips.png. The globe comes later.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/trip.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import '../accounts/accounts_provider.dart';
import 'destination_lookup.dart';
import 'itinerary_provider.dart';
import 'new_trip_screen.dart';
import 'day_screen.dart';

/// Whole days from [today] to [start]: 0 on the day you leave, negative after.
int daysUntil(DateTime start, {required DateTime today}) {
  // Both are plain dates, so UTC avoids a daylight-saving hour skewing the count.
  final from = DateTime.utc(today.year, today.month, today.day);
  final to = DateTime.utc(start.year, start.month, start.day);
  return to.difference(from).inDays;
}

/// "Fri 20 – Mon 23 Nov", or with both months when the trip crosses one.
String tripDateRange(Trip trip) {
  final sameMonth = trip.startDate.month == trip.endDate.month &&
      trip.startDate.year == trip.endDate.year;
  final start = DateFormat(sameMonth ? 'EEE d' : 'EEE d MMM').format(trip.startDate);
  final end = DateFormat('EEE d MMM').format(trip.endDate);
  return '$start – $end';
}

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
    // The next trip is the first one that hasn't ended yet; trips are sorted by start date.
    final upcoming = trips.where((t) => daysUntil(t.endDate, today: today) >= 0).firstOrNull;
    final others = trips.where((t) => t != upcoming).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Row(
            children: [
              Expanded(child: Text('Trips', style: text.headlineMedium)),
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
          const SizedBox(height: 24),
          if (_loadError != null)
            Text(_loadError!, style: text.bodyMedium?.copyWith(color: colors.coral)),
          if (trips.isEmpty && _loadError == null)
            Text('No trips yet. Tap + to plan one.',
                style: text.bodyLarge?.copyWith(color: colors.inkSoft)),
          if (upcoming != null)
            _UpcomingCard(trip: upcoming, today: today, onTap: () => _openTrip(upcoming)),
          for (final trip in others)
            _TripRow(trip: trip, today: today, onTap: () => _openTrip(trip)),
        ],
      ),
    );
  }
}

/// The next trip, drawn inverted: cream card, dark ink.
class _UpcomingCard extends StatelessWidget {
  final Trip trip;
  final DateTime today;
  final VoidCallback onTap;

  const _UpcomingCard({required this.trip, required this.today, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final days = daysUntil(trip.startDate, today: today);

    return Material(
      color: colors.ink,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.destination,
                        style: text.headlineMedium?.copyWith(color: colors.ground)),
                    const SizedBox(height: 4),
                    Text(tripDateRange(trip),
                        style: MeridianText.monoData.copyWith(color: colors.ground)),
                    const SizedBox(height: 16),
                    Text('${trip.numberOfDays} days',
                        style: MeridianText.monoData.copyWith(color: colors.ground)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (days > 0) Text('$days', style: MeridianText.nowNumber.copyWith(color: colors.ground)),
                  const SizedBox(height: 6),
                  Text(days > 0 ? 'days to go' : 'on now',
                      style: MeridianText.monoData.copyWith(color: colors.ground)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  final Trip trip;
  final DateTime today;
  final VoidCallback onTap;

  const _TripRow({required this.trip, required this.today, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final done = daysUntil(trip.endDate, today: today) < 0;
    final month = DateFormat('MMM yyyy').format(trip.startDate);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: done ? Colors.transparent : colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(trip.destination,
                      style: text.titleLarge?.copyWith(color: done ? colors.inkSoft : colors.ink)),
                ),
                Text(done ? '$month · done' : month,
                    style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
