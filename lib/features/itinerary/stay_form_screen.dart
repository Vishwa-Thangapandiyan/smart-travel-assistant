// Owner: Vishwa. Pick where you're staying on a trip: search a hotel or
// address with Nominatim inside the trip's destination, tap the right
// match, save. Also offers Remove. Saved on this phone (stays_provider.dart).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trip.dart';
import '../../theme/meridian_colors.dart';
import 'destination_lookup.dart';
import 'place_match_tile.dart';
import 'stays_provider.dart';

class StayFormScreen extends StatefulWidget {
  final Trip trip;
  final LookUpDestination lookUp;

  const StayFormScreen({super.key, required this.trip, required this.lookUp});

  @override
  State<StayFormScreen> createState() => _StayFormScreenState();
}

class _StayFormScreenState extends State<StayFormScreen> {
  final _query = TextEditingController();
  List<DestinationMatch> _matches = [];
  DestinationMatch? _picked;
  bool _searched = false;
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      // "Taj West End, Bangalore" keeps results inside the trip's city.
      final matches = await widget.lookUp('$query, ${widget.trip.destination}');
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _picked = matches.firstOrNull;
      });
    } on Exception {
      if (mounted) setState(() => _error = 'Couldn\'t search. Check your connection and try again.');
    }
    if (mounted) {
      setState(() {
        _searching = false;
        _searched = true;
      });
    }
  }

  Future<void> _save() async {
    final picked = _picked;
    if (picked == null) return;
    final navigator = Navigator.of(context);
    await context.read<StaysProvider>().setStay(
          widget.trip.id,
          Stay(name: picked.placeName, latitude: picked.latitude, longitude: picked.longitude),
        );
    navigator.pop();
  }

  Future<void> _remove() async {
    final navigator = Navigator.of(context);
    await context.read<StaysProvider>().removeStay(widget.trip.id);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final current = context.watch<StaysProvider>().stayFor(widget.trip.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Where you\'re staying'),
        actions: [
          if (current != null)
            IconButton(tooltip: 'Remove stay', onPressed: _remove, icon: Icon(Icons.delete_outline, color: colors.coral)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (current != null) ...[
              Text('Now: ${current.name}', style: text.bodyLarge),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _query,
              autofocus: current == null,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: 'Hotel, hostel or address',
                helperText: 'Each day\'s route starts here, and so does Navigate to the day\'s first stop.',
                helperMaxLines: 2,
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(tooltip: 'Search place', onPressed: _search, icon: const Icon(Icons.search)),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: text.bodySmall?.copyWith(color: colors.coral)),
              ),
            if (_searched && _error == null && _matches.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('No place found. Try the street or area name.', style: text.bodySmall),
              ),
            for (final match in _matches)
              PlaceMatchTile(match: match, picked: match == _picked, onTap: () => setState(() => _picked = match)),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _picked == null ? null : _save,
              child: const Text('Save stay'),
            ),
            const SizedBox(height: 8),
            Text('Saved on this phone only.', style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
