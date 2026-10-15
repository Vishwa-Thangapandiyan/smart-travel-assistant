// Owner: Vishwa. Adding a recommended place to a day of the trip as a stop
// (REQ-6.3), shared by the Explore grid and a place's detail screen.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/recommendation.dart';
import '../../models/trip.dart';
import '../itinerary/itinerary_provider.dart';

/// Adds [place] to [day], or asks which day first when [day] is null.
/// Says how it went in a snack bar.
Future<void> addPlaceToTrip(BuildContext context, Recommendation place, Trip trip, {int? day}) async {
  final itinerary = context.read<ItineraryProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final picked = day ?? await _pickDay(context, trip, place);
  if (picked == null) return;
  try {
    await itinerary.addStop(
      day: picked,
      title: place.name,
      locationName: place.name,
      latitude: place.latitude,
      longitude: place.longitude,
    );
    messenger.showSnackBar(SnackBar(content: Text('Added ${place.name} to Day $picked')));
  } on Exception {
    messenger.showSnackBar(SnackBar(content: Text('Couldn\'t add ${place.name}. Check your connection.')));
  }
}

Future<int?> _pickDay(BuildContext context, Trip trip, Recommendation place) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Add ${place.name} to…', style: Theme.of(context).textTheme.titleLarge),
          ),
          for (var day = 1; day <= trip.numberOfDays; day++)
            ListTile(
              title: Text('Day $day'),
              subtitle: Text(DateFormat('EEEE, d MMM').format(trip.startDate.add(Duration(days: day - 1)))),
              onTap: () => Navigator.pop(context, day),
            ),
        ],
      ),
    ),
  );
}

/// "On Sat 21", if this place is already a stop on the trip.
String? addedOnLabel(Recommendation place, Trip trip, ItineraryProvider itinerary) {
  final stop = itinerary.stops.where((s) => s.title == place.name).firstOrNull;
  if (stop == null) return null;
  return 'On ${DateFormat('EEE d').format(trip.startDate.add(Duration(days: stop.dayNumber - 1)))}';
}

// The seeded destinations in India; prices elsewhere aren't in rupees.
const _indianDestinations = {
  'Bangalore', 'Chennai', 'Goa', 'Jaipur', 'Mysore', 'Delhi', 'Agra',
  'Mumbai', 'Udaipur', 'Varanasi', 'Kochi', 'Rishikesh', 'Hampi',
};

/// "Free", or the price level as "₹" to "₹₹₹" in India and "\$" to "\$\$\$"
/// abroad — cheap to expensive for that city, not an amount.
String priceLabel(int priceLevel, String destination) {
  if (priceLevel == 0) return 'Free';
  return (_indianDestinations.contains(destination) ? '₹' : '\$') * priceLevel;
}
