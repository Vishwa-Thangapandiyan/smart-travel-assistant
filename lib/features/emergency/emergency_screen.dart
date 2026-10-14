// Owner: Sanjay. Placeholder from the app shell — replace with the real
// SOS screen (issues #19–#23). Design: design/screens/night-07-sos.png.
// Opened from the SOS button on every tab (lib/screens/home_shell.dart).

import 'package:flutter/material.dart';

import '../../widgets/feature_placeholder.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const FeaturePlaceholder(
        title: 'Get help',
        purpose: 'Nearby hospitals and police, and one tap to call.',
        trackedIn: 'EMERGENCY · SANJAY · #19–#23',
      ),
    );
  }
}
