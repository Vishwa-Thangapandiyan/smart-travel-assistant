// Owner: Vishwa. One trip, one day at a time: a switcher for the days
// (worked out from the trip's dates, never stored — Scene 3), then the
// day's stops in order with up/down buttons (REQ-2.2–2.4).
// Design: design/screens/night-03-day.png. The "now" card for a trip in
// progress and "From suggestions" (issue #18) come later.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/itinerary_item.dart';
import '../../models/trip.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import 'day_switcher.dart';
import 'destination_lookup.dart';
import 'itinerary_provider.dart';
import 'stop_form_screen.dart';

class DayScreen extends StatefulWidget {
  final Trip trip;
  final LookUpDestination lookUp;

  const DayScreen({super.key, required this.trip, required this.lookUp});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  int _day = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      await context.read<ItineraryProvider>().openTrip(widget.trip);
    } on Exception {
      if (mounted) setState(() => _error = 'Couldn\'t load this trip\'s stops. Check your connection.');
    }
  }

  DateTime _dateOf(int day) => widget.trip.startDate.add(Duration(days: day - 1));

  void _openForm({ItineraryItem? stop}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StopFormScreen(trip: widget.trip, day: _day, stop: stop, lookUp: widget.lookUp),
    ));
  }

  Future<void> _move(ItineraryItem stop, {required bool up}) async {
    try {
      await context.read<ItineraryProvider>().moveStop(stop, up: up);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t move the stop. Check your connection.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final provider = context.watch<ItineraryProvider>();
    final loaded = provider.currentTrip?.id == widget.trip.id;
    final stops = loaded ? provider.stopsForDay(_day) : <ItineraryItem>[];

    return Scaffold(
      appBar: AppBar(title: Text(widget.trip.destination)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          children: [
            DaySwitcher(
              days: widget.trip.numberOfDays,
              selected: _day,
              labelOf: (day) => DateFormat('EEE d').format(_dateOf(day)),
              onSelect: (day) => setState(() => _day = day),
            ),
            const SizedBox(height: 20),
            Text(DateFormat('EEEE, d MMM').format(_dateOf(_day)),
                style: MeridianText.monoHeading.copyWith(color: colors.ink)),
            const SizedBox(height: 4),
            Text('DAY $_day · ${stops.length} ${stops.length == 1 ? 'STOP' : 'STOPS'}',
                style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: text.bodyMedium?.copyWith(color: colors.coral)),
            if (!loaded && _error == null) const Center(child: CircularProgressIndicator()),
            if (loaded && stops.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No stops yet', style: text.bodyLarge?.copyWith(color: colors.inkSoft)),
              ),
            for (var i = 0; i < stops.length; i++)
              _StopRow(
                stop: stops[i],
                isFirst: i == 0,
                isLast: i == stops.length - 1,
                onTap: () => _openForm(stop: stops[i]),
                onUp: () => _move(stops[i], up: true),
                onDown: () => _move(stops[i], up: false),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: loaded ? () => _openForm() : null,
                icon: const Icon(Icons.add),
                label: const Text('Add a stop'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One stop on the rail: dot, name, note, time, and the reorder arrows.
class _StopRow extends StatelessWidget {
  final ItineraryItem stop;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const _StopRow({
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.onUp,
    required this.onDown,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    // Notes first; otherwise the place, unless it just repeats the name.
    final subtitle = stop.notes ?? (stop.locationName == stop.title ? null : stop.locationName);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.circle_outlined, size: 12, color: stop.latitude == null ? colors.inkSoft : colors.amber),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.title, style: text.titleLarge),
                  if (subtitle != null)
                    Text(subtitle, style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (stop.startTime != null)
              // Stored as "HH:mm:ss"; the screen shows hours and minutes.
              Text(stop.startTime!.substring(0, 5),
                  style: MeridianText.monoHeading.copyWith(fontSize: 18, color: colors.ink)),
            Column(
              children: [
                IconButton(
                  tooltip: 'Move up',
                  onPressed: isFirst ? null : onUp,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                IconButton(
                  tooltip: 'Move down',
                  onPressed: isLast ? null : onDown,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
