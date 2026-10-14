// Owner: Vishwa. Placeholder from the app shell — replace with the real
// sign-in form (issues #6–#8). Design: design/screens/night-01-sign-in.png.
// Shown first in real mode; fake data mode skips straight to the app.

import 'package:flutter/material.dart';

import '../../widgets/feature_placeholder.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: FeaturePlaceholder(
        title: 'Sign in',
        purpose: 'Your trips, budget and saved maps follow you.',
        trackedIn: 'ACCOUNTS · VISHWA · #6–#8',
      ),
    );
  }
}
