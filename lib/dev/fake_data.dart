// The demo trip every fake service returns: Bangalore, 20–23 Nov 2026 —
// the same trip as PROJECT-UNDERSTANDING.md and the screens in design/.
// Coordinates are the real places.

import '../models/emergency_contact.dart';
import '../models/itinerary_item.dart';
import '../models/last_known_location.dart';
import '../models/trip.dart';

const demoUserId = 'demo-user';

final _created = DateTime(2026, 10, 14);

final demoTrip = Trip(
  id: 'trip-bangalore',
  userId: demoUserId,
  destination: 'Bangalore',
  startDate: DateTime(2026, 11, 20),
  endDate: DateTime(2026, 11, 23),
  latitude: 12.9716,
  longitude: 77.5946,
  createdAt: _created,
);

// Every fake trip, demo first. Trips created in fake data mode are added
// here so the Trips screen shows them until the app restarts.
final fakeTrips = <Trip>[demoTrip];

/// For tests: forget created trips, keep the demo trip.
void resetFakeTrips() => fakeTrips
  ..clear()
  ..add(demoTrip);

ItineraryItem _stop(int day, int order, String title, double lat, double lng,
    {String? time, String? notes}) {
  return ItineraryItem(
    id: 'item-$day-$order',
    tripId: demoTrip.id,
    dayNumber: day,
    title: title,
    locationName: title,
    latitude: lat,
    longitude: lng,
    startTime: time,
    orderIndex: order,
    notes: notes,
    createdAt: _created,
  );
}

final demoItems = <ItineraryItem>[
  _stop(1, 0, 'Vidhana Soudha', 12.9796, 77.5907, time: '16:00:00'),
  _stop(1, 1, 'Vidyarthi Bhavan', 12.9452, 77.5713, time: '19:00:00', notes: 'Dinner'),
  _stop(2, 0, 'MTR, Lalbagh Road', 12.95519, 77.58572, time: '08:00:00', notes: 'Breakfast'),
  _stop(2, 1, 'Lalbagh Botanical Garden', 12.95073, 77.58483, time: '09:30:00', notes: 'Glass house, lake walk'),
  _stop(2, 2, 'Bangalore Palace', 12.99876, 77.59212, time: '12:30:00', notes: 'Audio tour at the gate'),
  _stop(2, 3, 'Cubbon Park', 12.97633, 77.59292, time: '16:00:00', notes: 'Walk to the State Library'),
  _stop(2, 4, 'Church Street', 12.97520, 77.60270, time: '19:00:00', notes: 'Dinner, bookshops'),
  _stop(3, 0, "Tipu Sultan's Summer Palace", 12.9593, 77.5737, time: '10:00:00'),
  _stop(3, 1, 'Commercial Street', 12.9822, 77.6083, time: '15:00:00'),
  _stop(4, 0, 'Kempegowda International Airport', 13.1986, 77.7066, time: '11:00:00'),
];

const demoGuideText =
    'Bangalore: mild weather year round. Auto-rickshaws and the Namma Metro '
    'cover most of the city; carry cash for small shops.';

/// Where the fake phone says it is: Cubbon Park.
const demoPosition = (latitude: 12.97633, longitude: 77.59292);

LastKnownLocation demoLastKnownLocation() => LastKnownLocation(
      userId: demoUserId,
      latitude: demoPosition.latitude,
      longitude: demoPosition.longitude,
      recordedAt: DateTime.now().subtract(const Duration(minutes: 12)),
    );

/// The national helplines seeded in db/seed.sql.
const demoEmergencyContacts = <EmergencyContact>[
  EmergencyContact(id: 'ec-112', serviceName: 'Emergency', phoneNumber: '112', isDefault: true),
  EmergencyContact(id: 'ec-100', serviceName: 'Police', phoneNumber: '100', isDefault: true),
  EmergencyContact(id: 'ec-108', serviceName: 'Ambulance', phoneNumber: '108', isDefault: true),
  EmergencyContact(id: 'ec-101', serviceName: 'Fire', phoneNumber: '101', isDefault: true),
];
