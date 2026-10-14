// Owner: Vishwa. Add or edit one stop: name, place, time and notes
// (REQ-2.2, REQ-2.4). The place is searched with Nominatim inside the
// trip's destination, so the stop gets coordinates for the map. Editing
// also offers Delete.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/itinerary_item.dart';
import '../../models/trip.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import 'destination_lookup.dart';
import 'itinerary_provider.dart';
import 'place_match_tile.dart';

class StopFormScreen extends StatefulWidget {
  final Trip trip;
  final int day;
  final ItineraryItem? stop; // null when adding
  final LookUpDestination lookUp;

  const StopFormScreen({
    super.key,
    required this.trip,
    required this.day,
    required this.lookUp,
    this.stop,
  });

  @override
  State<StopFormScreen> createState() => _StopFormScreenState();
}

class _StopFormScreenState extends State<StopFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _place;
  late final TextEditingController _notes;
  TimeOfDay? _time;

  // The stop's place: kept from the stop being edited until the user
  // searches again and picks something else.
  String? _locationName;
  double? _latitude;
  double? _longitude;

  List<DestinationMatch> _matches = [];
  bool _searched = false;
  bool _searching = false;
  bool _saving = false;
  String? _titleError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final stop = widget.stop;
    _title = TextEditingController(text: stop?.title ?? '');
    _place = TextEditingController(text: stop?.locationName ?? '');
    _notes = TextEditingController(text: stop?.notes ?? '');
    _locationName = stop?.locationName;
    _latitude = stop?.latitude;
    _longitude = stop?.longitude;
    final time = stop?.startTime;
    if (time != null) {
      // Stored as "HH:mm:ss".
      final parts = time.split(':');
      _time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final place = _place.text.trim();
    if (place.isEmpty) return;
    setState(() => _searching = true);
    // Searching "Cubbon Park, Bangalore" keeps results inside the trip's city.
    final matches = await widget.lookUp('$place, ${widget.trip.destination}');
    if (!mounted) return;
    setState(() {
      _searching = false;
      _searched = true;
      _matches = matches;
      if (matches.isNotEmpty) _pick(matches.first);
    });
  }

  void _pick(DestinationMatch match) {
    _place.text = match.placeName;
    _locationName = match.placeName;
    _latitude = match.latitude;
    _longitude = match.longitude;
  }

  // Typing a different place makes the old one wrong, so drop it.
  void _placeChanged(String text) {
    if (text.trim() == (_locationName ?? '')) return;
    setState(() {
      _matches = [];
      _searched = false;
      _locationName = text.trim().isEmpty ? null : text.trim();
      _latitude = null;
      _longitude = null;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0));
    if (picked != null) setState(() => _time = picked);
  }

  String? get _timeText {
    final time = _time;
    if (time == null) return null;
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Give the stop a name.');
      return;
    }
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final startTime = _timeText == null ? null : '$_timeText:00';
    final provider = context.read<ItineraryProvider>();
    final navigator = Navigator.of(context);

    setState(() {
      _titleError = null;
      _saveError = null;
      _saving = true;
    });
    try {
      final stop = widget.stop;
      if (stop == null) {
        await provider.addStop(
          day: widget.day,
          title: title,
          locationName: _locationName,
          latitude: _latitude,
          longitude: _longitude,
          startTime: startTime,
          notes: notes,
        );
      } else {
        await provider.updateStop(
          stop,
          title: title,
          locationName: _locationName,
          latitude: _latitude,
          longitude: _longitude,
          startTime: startTime,
          notes: notes,
        );
      }
      navigator.pop();
    } on Exception {
      setState(() {
        _saving = false;
        _saveError = 'Couldn\'t save the stop. Check your connection and try again.';
      });
    }
  }

  Future<void> _delete() async {
    final stop = widget.stop!;
    final provider = context.read<ItineraryProvider>();
    final navigator = Navigator.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${stop.title}?'),
        content: const Text('The stop and its notes are removed from this day.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await provider.deleteStop(stop);
      navigator.pop();
    } on Exception {
      setState(() => _saveError = 'Couldn\'t delete the stop. Check your connection and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final editing = widget.stop != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit stop' : 'Add a stop · Day ${widget.day}'),
        actions: [
          if (editing)
            IconButton(tooltip: 'Delete stop', onPressed: _delete, icon: Icon(Icons.delete_outline, color: colors.coral)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: 'Stop name', errorText: _titleError),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _place,
              textInputAction: TextInputAction.search,
              onChanged: _placeChanged,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: 'Place (to show it on the map)',
                helperText: _latitude == null ? 'Not on the map yet. Search to place it.' : 'On the map',
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(tooltip: 'Search place', onPressed: _search, icon: const Icon(Icons.search)),
              ),
            ),
            if (_searched && _matches.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('No place found. The stop can still be saved, just not on the map.',
                    style: text.bodySmall),
              ),
            for (final match in _matches)
              PlaceMatchTile(
                match: match,
                picked: match.latitude == _latitude && match.longitude == _longitude,
                onTap: () => setState(() => _pick(match)),
              ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickTime,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Time (optional)',
                  suffixIcon: _time == null
                      ? const Icon(Icons.schedule)
                      : IconButton(
                          tooltip: 'Clear time',
                          onPressed: () => setState(() => _time = null),
                          icon: const Icon(Icons.close),
                        ),
                ),
                isEmpty: _time == null,
                child: _timeText == null ? null : Text(_timeText!, style: MeridianText.monoData.copyWith(fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notes (optional)', alignLabelWithHint: true),
            ),
            const SizedBox(height: 28),
            if (_saveError != null) ...[
              Text(_saveError!, style: text.bodyMedium?.copyWith(color: colors.coral)),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save stop'),
            ),
          ],
        ),
      ),
    );
  }
}
