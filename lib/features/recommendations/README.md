# Destination recommendations — REQ-6.1–6.4

Owner: Vishwa · Branch: `flex/recommendations` · SRS 4.6 · Record:
[`docs/OWNERSHIP.md`](../../../docs/OWNERSHIP.md)

**Design:** follow [`DESIGN.md`](../../../DESIGN.md); screen picture: `design/screens/night-06-explore.png`.

A browsable list of places for the trip's destination that can be added
straight to the itinerary. Ranking is a plain database `ORDER BY` on a
hand-seeded table — REQ-6.4 makes that the required deliverable, not a
stand-in for something smarter. REQ-6.4 also allows this feature to
degrade gracefully if time runs short, so it ships last.

## Tasks

1. Seed real place names for 3–5 demo destinations (10–15 places each) in
   `db/seed.sql`, replacing the `-- TODO` marker. "Restaurant 1" looks like
   a placeholder — use real listings.
2. The feed: query `recommendations` filtered by destination and category,
   ordered by rating, mapped to `Recommendation` objects; filters for
   category, price and rating.
3. "Add to itinerary" from a card: build a new `ItineraryItem` from the
   tapped `Recommendation` and write it through `TripProvider`.
4. A place's own screen: tap a card for its photo, facts, a small map
   and Add to a day (`place_detail_screen.dart`). All 683 places have a free
   Wikimedia Commons photo in `image_url`, credited in `PHOTO-CREDITS.md`
   (for a few small restaurants and shops, the dish or street they're
   known for). A photo that fails to load shows a plain tile. A stop on
   the Day screen that is a seeded place shows the same photo
   (`stop_photos.dart`).
   Destinations (#57): Bangalore, Chennai, Goa, Jaipur, Mysore, Delhi,
   Agra, Mumbai, Udaipur, Varanasi, Kochi, Rishikesh and Hampi in India;
   London, Paris, Rome, Zurich, Dubai, Singapore, Bangkok, Bali, Tokyo
   and New York abroad. Added later: Hyderabad, Kolkata, Pune, Ahmedabad,
   Amritsar, Shimla, Manali, Darjeeling, Ooty, Munnar, Alappuzha,
   Puducherry, Madurai, Mahabalipuram, Jodhpur, Jaisalmer, Leh, Srinagar,
   Gangtok, Shillong, Khajuraho, Lucknow, Coorg, Thiruvananthapuram,
   Kanyakumari, Aurangabad, Port Blair and Bhubaneswar in India;
   Barcelona, Amsterdam, Berlin, Prague, Vienna, Istanbul, Athens, Cairo,
   Hong Kong, Seoul, Kyoto, Sydney, Melbourne, Kuala Lumpur, Hanoi, Ho Chi
   Minh City, Kathmandu, Colombo, San Francisco, Los Angeles, Toronto,
   Lisbon, Madrid, Venice, Florence, Edinburgh, Cape Town, Siem Reap and
   Phuket abroad. Other names (Bombay, Cochin, a country's name)
   find the seeded city through `seededDestination`. Prices show as ₹
   levels in India and $ levels abroad.
5. Optional, stop by 8 Nov 2026: a similarity ranking on top. If built,
   describe it in code and docs as a ranking function, never a model.

## Done when

- [x] The feed shows real places for the destination, ranked by a database
      query — REQ-6.1, REQ-6.2, REQ-6.4
- [x] A recommendation can be added straight to the itinerary — REQ-6.3
- [x] Seed data covers 3–5 destinations with real place names — REQ-6.1
- [x] Widened to 13 Indian destinations and 10 countries (#57)
- [x] Widened again to 80 destinations, 683 places: 41 in India and 39
      cities in 29 other countries, every place with a photo
