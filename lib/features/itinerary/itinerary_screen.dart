// Owner: Vishwa. Placeholder from the app shell — replace with the real
// Days screen (issues #9–#12). Design: design/screens/night-03-day.png.

import 'package:flutter/material.dart';

import '../../widgets/feature_placeholder.dart';

class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Days',
      purpose: 'Build each day by hand, stop by stop.',
      trackedIn: 'ITINERARY · VISHWA · #9–#12',
    );
  }
}
