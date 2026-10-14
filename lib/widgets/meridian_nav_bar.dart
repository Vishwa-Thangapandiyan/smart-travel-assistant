// The floating pill navigation from DESIGN.md §6: four tabs as round
// buttons, then SOS — on every main screen, one tap away.

import 'package:flutter/material.dart';

import '../theme/meridian_colors.dart';

class NavTab {
  final String label;
  final IconData icon;
  const NavTab(this.label, this.icon);
}

const navTabs = [
  NavTab('Days', Icons.route_outlined),
  NavTab('Map', Icons.map_outlined),
  NavTab('Budget', Icons.account_balance_wallet_outlined),
  NavTab('Explore', Icons.explore_outlined),
];

class MeridianNavBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onSos;

  const MeridianNavBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onSos,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;

    return Container(
      height: 68,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: ShapeDecoration(
        color: colors.surface,
        shape: StadiumBorder(side: BorderSide(color: colors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < navTabs.length; i++)
            IconButton(
              tooltip: navTabs[i].label,
              onPressed: () => onSelect(i),
              icon: Icon(navTabs[i].icon),
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: i == selected ? colors.ink : Colors.transparent,
                foregroundColor: i == selected ? colors.ground : colors.inkSoft,
              ),
            ),
          Semantics(
            label: 'Emergency help',
            button: true,
            excludeSemantics: true,
            child: FilledButton(
              onPressed: onSos,
              style: FilledButton.styleFrom(
                backgroundColor: colors.coral,
                foregroundColor: colors.onCoral,
                minimumSize: const Size(64, 48),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('SOS'),
            ),
          ),
        ],
      ),
    );
  }
}
