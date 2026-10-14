// Owner: Vishwa. The new-trip form: destination and two dates (REQ-2.1,
// PROJECT-UNDERSTANDING.md Scene 3). On Create it checks the form, looks
// the destination up once with Nominatim, saves the trip and returns it.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import '../accounts/accounts_provider.dart';
import 'destination_lookup.dart';
import 'itinerary_provider.dart';
import 'new_trip_check.dart';

class NewTripScreen extends StatefulWidget {
  final LookUpDestination lookUp;

  const NewTripScreen({super.key, required this.lookUp});

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {
  final _destination = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  NewTripCheck _check = const NewTripCheck();
  bool _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _destination.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _start : _end) ?? _start ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _create() async {
    final check = checkNewTrip(destination: _destination.text, start: _start, end: _end);
    setState(() {
      _check = check;
      _saveError = null;
    });
    if (!check.isValid) return;

    final userId = context.read<AccountsProvider>().userId;
    final provider = context.read<ItineraryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      final destination = _destination.text.trim();
      final match = await widget.lookUp(destination);
      final trip = await provider.createTrip(
        userId: userId,
        destination: destination,
        start: _start!,
        end: _end!,
        match: match,
      );
      // Say what Nominatim matched, so a wrong "Paris" is easy to spot.
      messenger.showSnackBar(SnackBar(
        content: Text(match == null
            ? 'Saved. We couldn\'t find $destination on the map, so the map will start at your first stop.'
            : 'Saved. On the map as: ${match.name}'),
      ));
      navigator.pop(trip);
    } on Exception {
      setState(() {
        _saving = false;
        _saveError = 'Couldn\'t save the trip. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final dateFormat = DateFormat('EEE d MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('New trip')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _destination,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Where are you going?',
                errorText: _check.destination,
              ),
            ),
            const SizedBox(height: 6),
            Text('Place search by Nominatim · © OpenStreetMap contributors',
                style: MeridianText.monoData.copyWith(color: colors.inkSoft, fontSize: 10)),
            const SizedBox(height: 20),
            _DateField(
              label: 'Leave on',
              value: _start == null ? null : dateFormat.format(_start!),
              error: _check.start,
              onTap: () => _pickDate(isStart: true),
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Come back on',
              value: _end == null ? null : dateFormat.format(_end!),
              error: _check.end,
              onTap: () => _pickDate(isStart: false),
            ),
            const SizedBox(height: 28),
            if (_saveError != null) ...[
              Text(_saveError!, style: text.bodyMedium?.copyWith(color: colors.coral)),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _saving ? null : _create,
              child: Text(_saving ? 'Saving…' : 'Create trip'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable field that opens the date picker; looks like the text field above it.
class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final String? error;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.value, required this.error, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        isEmpty: value == null,
        child: value == null ? null : Text(value!),
      ),
    );
  }
}
