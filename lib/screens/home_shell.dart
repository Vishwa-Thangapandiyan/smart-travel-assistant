// The main screen: one tab per feature under the floating nav bar.
// SOS opens the Emergency screen on top of whichever tab is showing.

import 'package:flutter/material.dart';

import '../features/budget/budget_screen.dart';
import '../features/emergency/emergency_screen.dart';
import '../features/itinerary/itinerary_screen.dart';
import '../features/maps/maps_screen.dart';
import '../features/recommendations/recommendations_screen.dart';
import '../widgets/meridian_nav_bar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  // Same order as navTabs: Days, Map, Budget, Explore.
  static const _screens = <Widget>[
    ItineraryScreen(),
    MapsScreen(),
    BudgetScreen(),
    RecommendationsScreen(),
  ];

  void _openSos() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencyScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // IndexedStack keeps each tab's state while you switch between them.
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: SafeArea(
        child: MeridianNavBar(
          selected: _tab,
          onSelect: (i) => setState(() => _tab = i),
          onSos: _openSos,
        ),
      ),
    );
  }
}
