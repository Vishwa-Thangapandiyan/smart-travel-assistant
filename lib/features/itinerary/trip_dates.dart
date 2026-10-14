// Owner: Vishwa. Date rules for trips, worked out on the phone from the
// two stored dates (nothing here is stored). Used by the Trips screen
// and ItineraryProvider.

import 'package:intl/intl.dart';

import '../../models/trip.dart';

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

/// The trip to show first: the earliest one that hasn't ended yet.
/// [trips] must be sorted by start date. Null when every trip is over.
Trip? nextTrip(List<Trip> trips, {required DateTime today}) {
  return trips.where((t) => daysUntil(t.endDate, today: today) >= 0).firstOrNull;
}
