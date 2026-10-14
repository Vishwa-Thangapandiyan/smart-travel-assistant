// Owner: Vishwa. One place Nominatim found, as a tappable row; the picked
// one is outlined in amber. Used by the new-trip and stop forms.

import 'package:flutter/material.dart';

import '../../theme/meridian_colors.dart';
import 'destination_lookup.dart';

class PlaceMatchTile extends StatelessWidget {
  final DestinationMatch match;
  final bool picked;
  final VoidCallback onTap;

  const PlaceMatchTile({super.key, required this.match, required this.picked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: picked ? colors.amber : colors.line),
        ),
        child: ListTile(
          onTap: onTap,
          title: Text(match.placeName),
          subtitle: Text(match.region, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Icon(
            picked ? Icons.check_circle : Icons.circle_outlined,
            color: picked ? colors.amber : colors.inkSoft,
          ),
        ),
      ),
    );
  }
}
