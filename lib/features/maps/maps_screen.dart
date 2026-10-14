// Owner: Vishwa. Placeholder from the app shell — replace with the real
// Map screen (issues #13–#15). Design: design/screens/night-04-map-saved-offline.png.

import 'package:flutter/material.dart';

import '../../widgets/feature_placeholder.dart';

class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Map',
      purpose: 'Your stops on a map, with the road between them.',
      trackedIn: 'MAPS · VISHWA · #13–#15',
    );
  }
}
