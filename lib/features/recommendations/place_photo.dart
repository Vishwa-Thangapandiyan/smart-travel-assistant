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

// One cover photo per seeded destination, reused from one of its places
// (so it is already credited in PHOTO-CREDITS.md). Others have none.
const _cityPhotos = {
  'bangalore': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8f/Bangalore_Mysore_Maharaja_Palace.jpg/960px-Bangalore_Mysore_Maharaja_Palace.jpg',
  'chennai': 'https://upload.wikimedia.org/wikipedia/commons/9/99/Kapaleeswarar1.jpg',
  'goa': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9c/Palolem_Beach%2C_South_Goa.jpg/960px-Palolem_Beach%2C_South_Goa.jpg',
  'jaipur': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/41/East_facade_Hawa_Mahal_Jaipur_from_ground_level_%28July_2022%29_-_img_01.jpg/960px-East_facade_Hawa_Mahal_Jaipur_from_ground_level_%28July_2022%29_-_img_01.jpg',
  'mysore': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/59/Mysore_Palace_%281%29.jpg/960px-Mysore_Palace_%281%29.jpg',
  'delhi': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ec/Humayun%27s_Tomb_New_Delhi_India.jpg/960px-Humayun%27s_Tomb_New_Delhi_India.jpg',
  'agra': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1d/Taj_Mahal_%28Edited%29.jpeg/960px-Taj_Mahal_%28Edited%29.jpeg',
  'mumbai': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3a/Mumbai_03-2016_30_Gateway_of_India.jpg/960px-Mumbai_03-2016_30_Gateway_of_India.jpg',
  'udaipur': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d2/Udaipur_Lake_India.JPG/960px-Udaipur_Lake_India.JPG',
  'varanasi': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/ad/Dasaswamedh_ghat-varanasi_india-andres_larin.jpg/960px-Dasaswamedh_ghat-varanasi_india-andres_larin.jpg',
  'kochi': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6e/Kochi%2C_Fishing_nets_at_sunset%2C_Kerala%2C_India.jpg/960px-Kochi%2C_Fishing_nets_at_sunset%2C_Kerala%2C_India.jpg',
  'rishikesh': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/75/Rishikesh-Lakshman_Jhula_by_Kaustubh_Nayyar.jpg/960px-Rishikesh-Lakshman_Jhula_by_Kaustubh_Nayyar.jpg',
  'hampi': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b9/Complex_of_Virupaksha_Temple%2C_Hampi_%2804%29.jpg/960px-Complex_of_Virupaksha_Temple%2C_Hampi_%2804%29.jpg',
  'london': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ec/Tower_of_London_from_the_Shard_%288515883950%29.jpg/960px-Tower_of_London_from_the_Shard_%288515883950%29.jpg',
  'paris': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/85/Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg/960px-Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg',
  'rome': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/de/Colosseo_2020.jpg/960px-Colosseo_2020.jpg',
  'zurich': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/11/Grossm%C3%BCnster_-_M%C3%BCnsterhof_2014-05-23_12-08-43.JPG/960px-Grossm%C3%BCnster_-_M%C3%BCnsterhof_2014-05-23_12-08-43.JPG',
  'dubai': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/90/Burj_Khalifa_%28worlds_tallest_building%29_and_the_Dubai_skyline_%2825781049892%29.jpg/960px-Burj_Khalifa_%28worlds_tallest_building%29_and_the_Dubai_skyline_%2825781049892%29.jpg',
  'singapore': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c7/Marina_Bay_Sands_%28I%29.jpg/960px-Marina_Bay_Sands_%28I%29.jpg',
  'bangkok': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2a/%E0%B9%80%E0%B8%88%E0%B8%94%E0%B8%B5%E0%B8%A2%E0%B9%8C%E0%B8%9B%E0%B8%A3%E0%B8%B0%E0%B8%98%E0%B8%B2%E0%B8%99%E0%B8%97%E0%B8%A3%E0%B8%87%E0%B8%9B%E0%B8%A3%E0%B8%B2%E0%B8%87%E0%B8%84%E0%B9%8C%E0%B8%A7%E0%B8%B1%E0%B8%94%E0%B8%AD%E0%B8%A3%E0%B8%B8%E0%B8%932.jpg/960px-%E0%B9%80%E0%B8%88%E0%B8%94%E0%B8%B5%E0%B8%A2%E0%B9%8C%E0%B8%9B%E0%B8%A3%E0%B8%B0%E0%B8%98%E0%B8%B2%E0%B8%99%E0%B8%97%E0%B8%A3%E0%B8%87%E0%B8%9B%E0%B8%A3%E0%B8%B2%E0%B8%87%E0%B8%84%E0%B9%8C%E0%B8%A7%E0%B8%B1%E0%B8%94%E0%B8%AD%E0%B8%A3%E0%B8%B8%E0%B8%932.jpg',
  'bali': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8d/TanahLot_2014.JPG/960px-TanahLot_2014.JPG',
  'tokyo': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/43/Sensoji_2023.jpg/960px-Sensoji_2023.jpg',
  'new york': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f0/Brooklyn_Bridge_and_the_Lower_Manhattan_skyline_from_Pebble_Beach%2C_New_York.jpg/960px-Brooklyn_Bridge_and_the_Lower_Manhattan_skyline_from_Pebble_Beach%2C_New_York.jpg',
};

/// The cover photo for a trip to [destination] ("Bengaluru" works too),
/// or null for a city Explore doesn't cover.
String? cityPhotoUrl(String destination) => _cityPhotos[seededDestination(destination).toLowerCase()];
