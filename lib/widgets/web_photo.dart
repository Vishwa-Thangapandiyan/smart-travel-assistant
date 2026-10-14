// Owner: Vishwa. A photo from the web (Wikimedia Commons), filling its
// box. [placeholder] shows while it loads, and stays when there is no
// photo or no internet, so a screen never shows a broken image.

import 'package:flutter/material.dart';

// Wikimedia asks apps to say who they are; requests without this can be refused.
const _userAgent = 'Meridian/1.0 (+https://github.com/Vishwa-Thangapandiyan/smart-travel-assistant)';

class WebPhoto extends StatelessWidget {
  final String? url;
  final Widget placeholder;

  const WebPhoto({super.key, required this.url, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    if (url == null) return placeholder;
    return Image.network(
      url!,
      headers: const {'User-Agent': _userAgent},
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, _) => frame == null ? placeholder : child,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}
