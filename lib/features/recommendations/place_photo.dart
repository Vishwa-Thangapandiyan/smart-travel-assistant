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
  'hyderabad': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/71/Charminar_Hyderabad_1.jpg/960px-Charminar_Hyderabad_1.jpg',
  'kolkata': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/72/Victoria_Memorial_situated_in_Kolkata.jpg/960px-Victoria_Memorial_situated_in_Kolkata.jpg',
  'pune': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4d/Front_view_of_Shaniwar_Wada_illuminated.jpg/960px-Front_view_of_Shaniwar_Wada_illuminated.jpg',
  'ahmedabad': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9a/GANDHI_ASHRAM_03.jpg/960px-GANDHI_ASHRAM_03.jpg',
  'amritsar': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/94/The_Golden_Temple_of_Amrithsar_7.jpg/960px-The_Golden_Temple_of_Amrithsar_7.jpg',
  'shimla': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/25/The_Ridge_Shimla_5.jpg/960px-The_Ridge_Shimla_5.jpg',
  'manali': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/99/Hidimba_Devi_Temple_-_North-east_View_-_Manali_2014-05-11_2648-2649.TIF/lossy-page1-960px-Hidimba_Devi_Temple_-_North-east_View_-_Manali_2014-05-11_2648-2649.TIF.jpg',
  'darjeeling': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d8/Tiger_Hill_Darjeeling_West_Bengal_India_%283%29.JPG/960px-Tiger_Hill_Darjeeling_West_Bengal_India_%283%29.JPG',
  'ooty': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c1/Botanical_Gardens_-_Ootacamund_%28Ooty%29_-_India_03.JPG/960px-Botanical_Gardens_-_Ootacamund_%28Ooty%29_-_India_03.JPG',
  'munnar': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/60/Eravikulam_National_Park_%2849444006652%29.jpg/960px-Eravikulam_National_Park_%2849444006652%29.jpg',
  'alappuzha': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/50/Kumarkom.jpg/960px-Kumarkom.jpg',
  'puducherry': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8c/Pondicherry-Rock_beach_aerial_view.jpg/960px-Pondicherry-Rock_beach_aerial_view.jpg',
  'madurai': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e9/An_aerial_view_of_Madurai_city_from_atop_of_Meenakshi_Amman_temple.jpg/960px-An_aerial_view_of_Madurai_city_from_atop_of_Meenakshi_Amman_temple.jpg',
  'mahabalipuram': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/74/Shore_Temple_-Mamallapuram_-Tamil_Nadu_-N-TN-C55.jpg/960px-Shore_Temple_-Mamallapuram_-Tamil_Nadu_-N-TN-C55.jpg',
  'jodhpur': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/99/Mehrangarh_Fort_sanhita.jpg/960px-Mehrangarh_Fort_sanhita.jpg',
  'jaisalmer': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/47/Jaisalmer_forteresse.jpg/960px-Jaisalmer_forteresse.jpg',
  'leh': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/36/Leh_Palace_2011.jpg/960px-Leh_Palace_2011.jpg',
  'srinagar': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e1/Dal_Lake_Hazratbal_Srinagar.jpg/960px-Dal_Lake_Hazratbal_Srinagar.jpg',
  'gangtok': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/99/Rumtek_Monastery_alias_Dharma_Chakra_Centre_near_Gangtok%2C_East_Sikkim_09.jpg/960px-Rumtek_Monastery_alias_Dharma_Chakra_Centre_near_Gangtok%2C_East_Sikkim_09.jpg',
  'shillong': 'https://upload.wikimedia.org/wikipedia/commons/6/6a/Umiam_Lake_-_by_Vikramjit_Kakati.png',
  'khajuraho': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e7/1_Khajuraho.jpg/960px-1_Khajuraho.jpg',
  'lucknow': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/04/Bara_Imambara%2C_Lucknow_2.jpg/960px-Bara_Imambara%2C_Lucknow_2.jpg',
  'coorg': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7a/Abbey_Falls_New.jpg/960px-Abbey_Falls_New.jpg',
  'thiruvananthapuram': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d2/Sree_Padmanabhaswamy_temple_01.jpg/960px-Sree_Padmanabhaswamy_temple_01.jpg',
  'kanyakumari': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b6/RockMemorial.jpg/960px-RockMemorial.jpg',
  'aurangabad': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c3/Ajanta_%2863%29.jpg/960px-Ajanta_%2863%29.jpg',
  'port blair': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fe/Front_View_of_Cellular_Jail%2C_Port_Blair.JPG/960px-Front_View_of_Cellular_Jail%2C_Port_Blair.JPG',
  'bhubaneswar': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5d/Lingaraj_Temple_%2C_Bhubaneswar.jpg/960px-Lingaraj_Temple_%2C_Bhubaneswar.jpg',
  'barcelona': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ef/SF_maig_2_cropped.jpg/960px-SF_maig_2_cropped.jpg',
  'amsterdam': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/80/South_facade_of_the_Rijksmuseum_Amsterdam_%28DSCF0528%29.jpg/960px-South_facade_of_the_Rijksmuseum_Amsterdam_%28DSCF0528%29.jpg',
  'berlin': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a6/Brandenburger_Tor_abends.jpg/960px-Brandenburger_Tor_abends.jpg',
  'prague': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/22/Prague_07-2016_view_from_Lesser_Town_Tower_of_Charles_Bridge_img3.jpg/960px-Prague_07-2016_view_from_Lesser_Town_Tower_of_Charles_Bridge_img3.jpg',
  'vienna': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c9/Wien_-_Schloss_Sch%C3%B6nbrunn.JPG/960px-Wien_-_Schloss_Sch%C3%B6nbrunn.JPG',
  'istanbul': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4a/Hagia_Sophia_%28228968325%29.jpeg/960px-Hagia_Sophia_%28228968325%29.jpeg',
  'athens': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2c/1029_Acropolis_of_Athens_in_Greece_at_night_Photo_by_Giles_Laurent.jpg/960px-1029_Acropolis_of_Athens_in_Greece_at_night_Photo_by_Giles_Laurent.jpg',
  'cairo': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/96/Pyramids_of_the_Giza_Necropolis.jpg/960px-Pyramids_of_the_Giza_Necropolis.jpg',
  'hong kong': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7d/High_West_and_Victoria_Peak_from_Victoria_Gap_%28crop1%29.jpg/960px-High_West_and_Victoria_Peak_from_Victoria_Gap_%28crop1%29.jpg',
  'seoul': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/63/%EA%B4%91%ED%99%94%EB%AC%B8_%EC%9B%94%EB%8C%80.jpg/960px-%EA%B4%91%ED%99%94%EB%AC%B8_%EC%9B%94%EB%8C%80.jpg',
  'kyoto': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0e/Torii_path_with_lantern_at_Fushimi_Inari_Taisha_Shrine%2C_Kyoto%2C_Japan.jpg/960px-Torii_path_with_lantern_at_Fushimi_Inari_Taisha_Shrine%2C_Kyoto%2C_Japan.jpg',
  'sydney': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/80/00_1375_Sydney_Opera_House_%28Australia%29.jpg/960px-00_1375_Sydney_Opera_House_%28Australia%29.jpg',
  'melbourne': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/55/Fed_Square%2C_Melbourne%2C_west_view_20230219_1.jpg/960px-Fed_Square%2C_Melbourne%2C_west_view_20230219_1.jpg',
  'kuala lumpur': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f5/Petronas_twin_towers_at_night.jpg/960px-Petronas_twin_towers_at_night.jpg',
  'hanoi': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/79/Thap_Rua.jpg/960px-Thap_Rua.jpg',
  'ho chi minh city': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f5/Ben_Thanh%2C_Ciudad_Ho_Chi_Minh%2C_Vietnam%2C_2013-08-14%2C_DD_01.JPG/960px-Ben_Thanh%2C_Ciudad_Ho_Chi_Minh%2C_Vietnam%2C_2013-08-14%2C_DD_01.JPG',
  'kathmandu': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4d/Boudhanath_stupa_%2C_Kathmandu%2C_Nepal.jpg/960px-Boudhanath_stupa_%2C_Kathmandu%2C_Nepal.jpg',
  'colombo': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9a/Gangaramaya_Temple.JPG/960px-Gangaramaya_Temple.JPG',
  'san francisco': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/bf/Golden_Gate_Bridge_as_seen_from_Battery_East.jpg/960px-Golden_Gate_Bridge_as_seen_from_Battery_East.jpg',
  'los angeles': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4b/Griffith_observatory_2006.jpg/960px-Griffith_observatory_2006.jpg',
  'toronto': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2d/Toronto_-_ON_-_CN_Tower_bei_Nacht2.jpg/960px-Toronto_-_ON_-_CN_Tower_bei_Nacht2.jpg',
  'lisbon': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/65/Torre_Bel%C3%A9m_April_2009-4a.jpg/960px-Torre_Bel%C3%A9m_April_2009-4a.jpg',
  'madrid': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/68/Museo_del_Prado_2016_%2825185969599%29.jpg/960px-Museo_del_Prado_2016_%2825185969599%29.jpg',
  'venice': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/61/Venezia_Basilica_di_San_Marco_Fassade_2.jpg/960px-Venezia_Basilica_di_San_Marco_Fassade_2.jpg',
  'florence': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c7/Cattedrale_di_Santa_Maria_del_Fiore_%E2%80%93_Il_Duomo_di_Firenze.jpg/960px-Cattedrale_di_Santa_Maria_del_Fiore_%E2%80%93_Il_Duomo_di_Firenze.jpg',
  'edinburgh': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/59/City_of_Edinburgh_-_Edinburgh_Castle_-_20140421004403.jpg/960px-City_of_Edinburgh_-_Edinburgh_Castle_-_20140421004403.jpg',
  'cape town': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/dc/Table_Mountain_DanieVDM.jpg/960px-Table_Mountain_DanieVDM.jpg',
  'siem reap': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/41/Angkor_Wat.jpg/960px-Angkor_Wat.jpg',
  'phuket': 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/88/Patong_Beach.jpg/960px-Patong_Beach.jpg',
};

/// The cover photo for a trip to [destination] ("Bengaluru" works too),
/// or null for a city Explore doesn't cover.
String? cityPhotoUrl(String destination) => _cityPhotos[seededDestination(destination).toLowerCase()];
