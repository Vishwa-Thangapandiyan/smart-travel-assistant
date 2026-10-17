// Owner: Vishwa. The brand intro: the glowing Meridian globe, played once
// each time the app starts, then the app. A tap skips it. It is an animated
// WebP (assets/brand/intro.webp, made from docs/logo_assets) rather than a
// video, so it needs no video package; the original's audio was near
// silent and is left out. Skipped when the phone asks for less motion.

import 'dart:async';

import 'package:flutter/material.dart';

/// The intro's own near-black, the same as the Android launch screen, so the
/// handover from Android's splash to the animation shows no seam.
const introBackground = Color(0xFF0D0904);

class IntroScreen extends StatefulWidget {
  /// Called once, when the animation has played or the user taps.
  final VoidCallback onDone;

  /// The animation is 4 seconds long.
  final Duration length;

  const IntroScreen({super.key, required this.onDone, this.length = const Duration(seconds: 4)});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  Timer? _timer;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || _done) return;
    // "Remove animations" in the phone's settings: go straight to the app.
    if (MediaQuery.of(context).disableAnimations) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _timer = Timer(widget.length, _finish);
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _timer?.cancel();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _finish,
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: introBackground,
        child: Center(
          child: Semantics(
            label: 'Meridian, smart travel assistant. Tap to skip.',
            child: Image.asset(
              'assets/brand/intro.webp',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              // If the file can't be read, show the logo instead of nothing.
              errorBuilder: (context, error, stack) =>
                  Image.asset('assets/brand/meridian-mark.png', width: 180, height: 180),
            ),
          ),
        ),
      ),
    );
  }
}
