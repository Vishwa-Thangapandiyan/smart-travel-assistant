// Owner: Vishwa. Placeholder from the app shell — replace with the real
// Explore screen (issues #16–#18). Design: design/screens/night-06-explore.png.

import 'package:flutter/material.dart';

import '../../widgets/feature_placeholder.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Explore',
      purpose: 'Places worth a look, one tap to add.',
      trackedIn: 'RECOMMENDATIONS · VISHWA · #16–#18',
    );
  }
}
