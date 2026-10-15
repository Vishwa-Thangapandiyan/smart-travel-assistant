// Owner: Vishwa. One trip, one day at a time: a switcher for the days
// (worked out from the trip's dates, never stored — Scene 3), then the
// day's stops in order with up/down buttons (REQ-2.2–2.4).
// "From suggestions" opens Explore to add a seeded place to this day; a
// stop that is a seeded place shows that place's photo.
// Below the stops, where you're staying (on this phone only), Sanjay's
// Download for offline button and, once the trip is saved on the phone, a
// way into the saved copy (REQ-4.3). The app bar deletes the whole trip.
// Design: design/screens/night-03-day.png. The "now" card for a trip in
// progress comes later.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/itinerary_item.dart';
import '../../models/trip.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import '../offline/download_trip_button.dart';
import '../offline/offline_provider.dart';
import '../offline/saved_trip_screen.dart';
import '../../widgets/web_photo.dart';
import '../recommendations/recommendations_screen.dart';
import '../recommendations/stop_photos.dart';
import 'day_switcher.dart';
import 'destination_lookup.dart';
import 'itinerary_provider.dart';
import 'stay_form_screen.dart';
import 'stays_provider.dart';
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
  Map<String, String> _photos = {}; // seeded place name → photo, for the stops

  @override
  void initState() {
    super.initState();
    _open();
    _loadPhotos();
  }

  // Photos are extra: with no connection the stops simply show without them.
  Future<void> _loadPhotos() async {
    try {
      final photos = await placePhotosFor(widget.trip.destination);
      if (mounted) setState(() => _photos = photos);
    } on Exception {
      // Keep the plain list.
    }
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

  void _openSuggestions() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecommendationsScreen(addToDay: _day)));
  }

  void _openStay() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StayFormScreen(trip: widget.trip, lookUp: widget.lookUp),
    ));
  }

  Future<void> _deleteTrip() async {
    final itinerary = context.read<ItineraryProvider>();
    final stays = context.read<StaysProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete the ${widget.trip.destination} trip?'),
        content: const Text('Every day and stop, the budget and the expenses of this trip are deleted. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await itinerary.deleteTrip(widget.trip);
      await stays.removeStay(widget.trip.id);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('Deleted the ${widget.trip.destination} trip')));
    } on Exception {
      messenger.showSnackBar(const SnackBar(content: Text('Couldn\'t delete the trip. Check your connection.')));
    }
  }

  void _openSavedCopy() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SavedTripScreen(tripId: widget.trip.id)));
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
    final saved = context.watch<OfflineProvider>().isDownloaded(widget.trip.id);
    final stay = context.watch<StaysProvider>().stayFor(widget.trip.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.destination),
        actions: [
          IconButton(
            tooltip: 'Delete trip',
            onPressed: _deleteTrip,
            icon: Icon(Icons.delete_outline, color: colors.coral),
          ),
        ],
      ),
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
                photoUrl: photoForStop(stops[i], _photos),
                isFirst: i == 0,
                isLast: i == stops.length - 1,
                onTap: () => _openForm(stop: stops[i]),
                onUp: () => _move(stops[i], up: true),
                onDown: () => _move(stops[i], up: false),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: loaded ? () => _openForm() : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add a stop'),
                ),
                TextButton(
                  onPressed: loaded ? _openSuggestions : null,
                  child: Text('From suggestions', style: TextStyle(color: colors.amberText)),
                ),
              ],
            ),
            const SizedBox(height: 36),
            Text('STAY', style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
            const SizedBox(height: 6),
            if (stay == null)
              Text('Where you sleep. Each day\'s route and Navigate to the first stop start there.',
                  style: text.bodyMedium?.copyWith(color: colors.inkSoft))
            else
              Row(
                children: [
                  Icon(Icons.hotel_outlined, size: 18, color: colors.amber),
                  const SizedBox(width: 10),
                  Expanded(child: Text(stay.name, style: text.titleLarge?.copyWith(fontSize: 16))),
                ],
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _openStay,
                icon: Icon(stay == null ? Icons.add : Icons.edit_outlined),
                label: Text(stay == null ? 'Add where you\'re staying' : 'Change stay'),
              ),
            ),
            const SizedBox(height: 36),
            Text('OFFLINE', style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
            const SizedBox(height: 6),
            Text('Save the whole trip on this phone to read it with no signal.',
                style: text.bodyMedium?.copyWith(color: colors.inkSoft)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DownloadTripButton(tripId: widget.trip.id),
                // Also the way in when the stops above couldn't load.
                if (saved) TextButton(onPressed: _openSavedCopy, child: const Text('Open saved copy')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One stop on the rail: dot, photo if it's a seeded place, name, note,
/// time, and the reorder arrows.
class _StopRow extends StatelessWidget {
  final ItineraryItem stop;
  final String? photoUrl;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const _StopRow({
    required this.stop,
    required this.photoUrl,
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
            if (photoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: WebPhoto(url: photoUrl, placeholder: ColoredBox(color: colors.ember)),
                ),
              ),
              const SizedBox(width: 12),
            ],
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
