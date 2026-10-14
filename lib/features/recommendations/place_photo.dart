// Owner: Vishwa. A place's photo (recommendations.image_url, from
// Wikimedia Commons), or a warm tile with the category's icon when the
// place has no photo or the phone is offline. Credits: PHOTO-CREDITS.md.

import 'package:flutter/material.dart';

import '../../models/recommendation.dart';
import '../../theme/meridian_colors.dart';

const _categoryIcons = {
  'attraction': Icons.account_balance_outlined,
  'restaurant': Icons.restaurant_outlined,
  'nature': Icons.park_outlined,
  'museum': Icons.museum_outlined,
  'shopping': Icons.shopping_bag_outlined,
};

// Wikimedia asks apps to say who they are; requests without this can be refused.
const _userAgent = 'Meridian/1.0 (+https://github.com/Vishwa-Thangapandiyan/smart-travel-assistant)';

class PlacePhoto extends StatelessWidget {
  final Recommendation place;
  final double iconSize;

  const PlacePhoto({super.key, required this.place, this.iconSize = 40});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final placeholder = Container(
      color: colors.ember,
      alignment: Alignment.center,
      child: Icon(_categoryIcons[place.category] ?? Icons.place_outlined, size: iconSize, color: colors.inkSoft),
    );

    final url = place.imageUrl;
    if (url == null) return placeholder;
    return Image.network(
      url,
      headers: const {'User-Agent': _userAgent},
      fit: BoxFit.cover,
      // The tile shows while the photo loads, and stays if it can't.
      frameBuilder: (context, child, frame, _) => frame == null ? placeholder : child,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}

/// The Commons page of a photo, which names its author and licence.
/// Photo URLs look like `.../commons/thumb/7/78/NAME/960px-NAME`
/// or `.../commons/7/78/NAME`.
Uri? photoSourcePage(String imageUrl) {
  final parts = Uri.parse(imageUrl).pathSegments;
  final commons = parts.indexOf('commons');
  if (commons < 0) return null;
  var rest = parts.sublist(commons + 1);
  if (rest.isNotEmpty && rest.first == 'thumb') rest = rest.sublist(1);
  if (rest.length < 3) return null;
  return Uri.https('commons.wikimedia.org', '/wiki/File:${rest[2]}');
}
