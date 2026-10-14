// Owner: Vishwa. The pill of a trip's days ("Fri 20", "Sat 21" …); the
// selected day is cream. Used by the Day and Map screens.

import 'package:flutter/material.dart';

import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';

class DaySwitcher extends StatelessWidget {
  final int days;
  final int selected;
  final String Function(int day) labelOf;
  final ValueChanged<int> onSelect;

  const DaySwitcher({super.key, required this.days, required this.selected, required this.labelOf, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: colors.surface,
        shape: StadiumBorder(side: BorderSide(color: colors.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var day = 1; day <= days; day++)
              TextButton(
                onPressed: () => onSelect(day),
                style: TextButton.styleFrom(
                  backgroundColor: day == selected ? colors.ink : Colors.transparent,
                  foregroundColor: day == selected ? colors.ground : colors.inkSoft,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(labelOf(day), style: MeridianText.monoData),
              ),
          ],
        ),
      ),
    );
  }
}
