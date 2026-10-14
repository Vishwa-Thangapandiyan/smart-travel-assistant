// Owner: Sanjay. Placeholder from the app shell — replace with the real
// read-only saved trip (issue #26). Other screens open it; they don't
// edit it.

import 'package:flutter/material.dart';

import '../../widgets/feature_placeholder.dart';

class SavedTripScreen extends StatelessWidget {
  final String tripId;

  const SavedTripScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const FeaturePlaceholder(
        title: 'Saved trip',
        purpose: 'Your trip, readable with no signal.',
        trackedIn: 'OFFLINE · SANJAY · #25–#26',
      ),
    );
  }
}
