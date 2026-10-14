// Owner: Vishwa. A place's photo (recommendations.image_url, from
// Wikimedia Commons), or a warm tile with the category's icon when the
// place has no photo or the phone is offline. Credits: PHOTO-CREDITS.md.
// Also the cover photo of each seeded city, for the Trips screen.

import 'package:flutter/material.dart';

import '../../models/recommendation.dart';
import '../../theme/meridian_colors.dart';
import '../../widgets/web_photo.dart';
import 'recommendations_provider.dart' show seededDestination;

const _categoryIcons = {
  'attraction': Icons.account_balance_outlined,
  'restaurant': Icons.restaurant_outlined,
  'nature': Icons.park_outlined,
  'museum': Icons.museum_outlined,
  'shopping': Icons.shopping_bag_outlined,
};

class PlacePhoto extends StatelessWidget {
  final Recommendation place;
  final double iconSize;

  const PlacePhoto({super.key, required this.place, this.iconSize = 40});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;

    return WebPhoto(
      url: place.imageUrl,
      placeholder: Container(
        color: colors.ember,
        alignment: Alignment.center,
        child: Icon(_categoryIcons[place.category] ?? Icons.place_outlined, size: iconSize, color: colors.inkSoft),
      ),
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

// One cover photo per seeded city, reused from its places above (so it is
// already credited in PHOTO-CREDITS.md). Other destinations have none.
const _cityPhotos = {
  'bangalore': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8f/Bangalore_Mysore_Maharaja_Palace.jpg/960px-Bangalore_Mysore_Maharaja_Palace.jpg',
  'chennai': 'https://upload.wikimedia.org/wikipedia/commons/9/99/Kapaleeswarar1.jpg',
  'goa': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9c/Palolem_Beach%2C_South_Goa.jpg/960px-Palolem_Beach%2C_South_Goa.jpg',
  'jaipur': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/41/East_facade_Hawa_Mahal_Jaipur_from_ground_level_%28July_2022%29_-_img_01.jpg/960px-East_facade_Hawa_Mahal_Jaipur_from_ground_level_%28July_2022%29_-_img_01.jpg',
  'mysore': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/59/Mysore_Palace_%281%29.jpg/960px-Mysore_Palace_%281%29.jpg',
};

/// The cover photo for a trip to [destination] ("Bengaluru" works too),
/// or null for a city Explore doesn't cover.
String? cityPhotoUrl(String destination) => _cityPhotos[seededDestination(destination).toLowerCase()];
