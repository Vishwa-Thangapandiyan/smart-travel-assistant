// Owner: Santhosh. Placeholder from the app shell — replace with the real
// Budget screen (issues #27–#30). Design: design/screens/night-05-budget.png.

import 'package:flutter/material.dart';

import '../../widgets/feature_placeholder.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Budget',
      purpose: 'Split a budget by category and log what you spend.',
      trackedIn: 'BUDGET · SANTHOSH · #27–#30',
    );
  }
}
