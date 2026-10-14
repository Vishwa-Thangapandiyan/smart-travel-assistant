// The screen each feature shows until its owner builds the real one.
// Owners replace their screen entirely; this widget then goes unused.

import 'package:flutter/material.dart';

import '../theme/meridian_colors.dart';
import '../theme/meridian_theme.dart';

class FeaturePlaceholder extends StatelessWidget {
  final String title;
  final String purpose;
  final String trackedIn; // e.g. "Budget · Santhosh · issues #27–#30"

  const FeaturePlaceholder({
    super.key,
    required this.title,
    required this.purpose,
    required this.trackedIn,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(purpose, style: text.bodyLarge?.copyWith(color: colors.inkSoft)),
            const SizedBox(height: 16),
            Text(trackedIn, style: MeridianText.monoData.copyWith(color: colors.amberText)),
          ],
        ),
      ),
    );
  }
}
