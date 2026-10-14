// Owner: Sanjay. Placeholder from the app shell — the real button
// downloads the trip and shows "Downloaded ✓" (issue #26). Vishwa's trip
// screen places it; it is disabled until it works.

import 'package:flutter/material.dart';

class DownloadTripButton extends StatelessWidget {
  final String tripId;

  const DownloadTripButton({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return const OutlinedButton(
      onPressed: null,
      child: Text('Download for offline'),
    );
  }
}
