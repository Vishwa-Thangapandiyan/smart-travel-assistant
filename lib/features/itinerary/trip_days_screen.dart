// Owner: Vishwa. A trip's days, worked out from its two dates every time
// it opens — days are never stored (PROJECT-UNDERSTANDING.md Scene 3).
// Read-only for now; adding, editing and reordering stops arrive with
// issues #10–#12, along with the full Day design (night-03-day.png).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/itinerary_item.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';

class TripDaysScreen extends StatelessWidget {
  final Trip trip;

  const TripDaysScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(trip.destination)),
      body: FutureBuilder<List<ItineraryItem>>(
        future: getItineraryItems(trip.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Couldn\'t load this trip\'s stops.',
                  style: text.bodyMedium?.copyWith(color: colors.coral)),
            );
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              for (var day = 1; day <= trip.numberOfDays; day++) ...[
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('Day $day', style: MeridianText.monoHeading.copyWith(color: colors.ink)),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEE d MMM').format(trip.startDate.add(Duration(days: day - 1))),
                      style: MeridianText.monoData.copyWith(color: colors.inkSoft),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._stopsFor(day, items, text, colors),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _stopsFor(int day, List<ItineraryItem> items, TextTheme text, MeridianColors colors) {
    final stops = items.where((i) => i.dayNumber == day).toList();
    if (stops.isEmpty) {
      return [Text('No stops yet', style: text.bodyMedium?.copyWith(color: colors.inkSoft))];
    }
    return [
      for (final stop in stops)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                // Stored as "HH:mm:ss"; the screen shows hours and minutes.
                child: Text(stop.startTime?.substring(0, 5) ?? '',
                    style: MeridianText.monoData.copyWith(color: colors.amberText)),
              ),
              Expanded(child: Text(stop.title, style: text.bodyLarge)),
            ],
          ),
        ),
    ];
  }
}
