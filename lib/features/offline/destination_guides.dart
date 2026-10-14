// Owner: Sanjay. The guide text a downloaded trip carries (issue #24):
// a short, hand-written note for each of the five demo destinations —
// the same cities seeded in `recommendations`. Written once, by us, and
// bundled with the app, so there is no extra table and no outside source.
// A trip to any other place downloads without a guide.

import '../recommendations/recommendations_provider.dart' show seededDestination;

const _guides = {
  'bangalore': 'Bangalore (Bengaluru) has mild weather all year; carry a light '
      'layer for the evenings. Auto-rickshaws and the Namma Metro cover most of '
      'the city — agree an auto fare or ask for the meter before you set off. '
      'Traffic is heavy at rush hour, so leave extra time. Carry some cash for '
      'small shops and street food.',
  'chennai': 'Chennai is hot and humid for most of the year, with heavy rain '
      'from October to December. The suburban trains, MRTS and Chennai Metro '
      'link the main areas; autos are everywhere. Temples ask you to remove '
      'footwear and dress modestly. Drink bottled water and keep cash for small shops.',
  'goa': 'Goa is spread out: North Goa has the busy beaches, South Goa the quiet '
      'ones, and Panaji sits in between. Most visitors get around by taxi or a '
      'rented scooter — wear a helmet. The monsoon (June to September) brings '
      'rough seas, so swim only where lifeguards are on duty.',
  'jaipur': 'Jaipur is very hot from April to June and cool in the winter '
      'evenings. The old walled city is easiest on foot or by auto; the forts '
      'outside it are best reached by taxi. Start early to avoid crowds and '
      'heat, and dress modestly at temples.',
  'mysore': 'Mysore (Mysuru) is calm and compact, with pleasant weather most of '
      'the year. Autos and city buses cover the centre; the palace and Chamundi '
      'Hill are close together. The palace is lit up on Sunday evenings and '
      'festival nights. Remove footwear at temples.',
};

/// The guide for [destination], or null if there isn't one.
/// "Bengaluru" finds Bangalore's guide, like Explore does.
String? guideFor(String destination) => _guides[seededDestination(destination).toLowerCase()];
